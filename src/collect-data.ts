import fs from "fs";
import fsp from "fs/promises";
import path from "path";
import { Octokit, type RestEndpointMethodTypes } from "@octokit/rest";
import { graphql } from "@octokit/graphql";
import { CSV_HEADERS } from "./lib/models/csv.ts";
import { getRepositories, type RepoData } from "./services/github/resources/repo.ts";
import { GITHUB_ORG, GITHUB_TOKEN } from "./constants.ts";
import { github } from "./services/github/client.ts";
import type { PullRequest } from "./services/github/resources/__generated__/types.ts";
import { getPullRequests } from "./services/github/resources/pullRequest.ts";


type RepoListItem = RestEndpointMethodTypes["repos"]["listForOrg"]["response"]["data"][number];
type CommitItem = RestEndpointMethodTypes["repos"]["listCommits"]["response"]["data"][number];


const DATA_DIR = "data";
const COMMITS_PER_PAGE = 100;
const REPOS_PER_PAGE = 100;
const SLEEP_BETWEEN_REPOS_MS = 500;

const sleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));

const ensureDir = async (dir: string) => {
  await fsp.mkdir(dir, { recursive: true });
};

const csvValue = (v: unknown): string => {
  const s = String(v ?? "");
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};

const csvLine = (values: ReadonlyArray<unknown>): string =>
  values.map(csvValue).join(",") + "\n";

const writeLine = (ws: fs.WriteStream, line: string) => {
  if (!ws.write(line)) {
    return new Promise<void>((resolve) => ws.once("drain", resolve));
  }
  return Promise.resolve();
};

const repoCsvRow = (r: RepoData): string => {
  return csvLine([
    r.name,
    `${GITHUB_ORG}/${r.name}`,
    r.description ?? "",
    r.primaryLanguage?.name ?? "",
    r.stargazerCount,
    r.forkCount,
    r.createdAt,
    r.updatedAt,
    r.url,
  ]);
};


const commitCsvRow = (repoName: string, c: CommitItem): string => {
  const authorLogin = (c.author && c.author.login) ? c.author.login : "";
  const committerLogin = (c.committer && c.committer.login) ? c.committer.login : "";
  const message = c.commit.message ?? "";
  const date = c.commit.author?.date ?? "";
  return csvLine([repoName, c.sha, authorLogin, committerLogin, message, date]);
};

const listCommits = async (
  owner: string,
  repo: string
): Promise<CommitItem[]> => {
  return github.paginate(github.rest.repos.listCommits, {
    owner,
    repo,
    per_page: COMMITS_PER_PAGE,
  });
};

const prCsvRow = (repoName: string, n: PullRequest): string  => {
  const assignees =
    n.assignees?.nodes?.map((x) => (x ? x.login : null)).filter(Boolean).join(",") ?? "";
  const requested =
    n.reviewRequests?.nodes
      ?.map((x) => (x?.requestedReviewer && "login" in x.requestedReviewer ? x.requestedReviewer.login : undefined))
      .filter(Boolean)
      .join(",") ?? "";
  const commentAuthors =
    n.comments?.nodes?.map((x) => (x?.author ? x.author.login : null)).filter(Boolean).join(";") ?? "";

  return csvLine([
    repoName,
    n.number,
    n.title,
    n.state,
    n.author?.login ?? "",
    n.createdAt,
    n.mergedAt ?? "",
    n.mergedBy?.login ?? "",
    assignees,
    requested,
    n.comments?.totalCount ?? 0,
    n.additions ?? 0,
    n.deletions ?? 0,
    commentAuthors,
  ]);
};

const reviewCsvRows = (repoName: string, n: PullRequest): string[] => {
  const prNumber = n.number;
  const nodes = n.reviews?.nodes ?? [];
  return nodes
    .map((r) =>
      r
        ? csvLine([repoName, prNumber, r.author?.login ?? "", r.state, r.submittedAt ?? ""])
        : null
    )
    .filter((x): x is string => Boolean(x));
};

const main = async () => {
  const org = process.argv[2];
  if (!org) {
    // match bash usage message style
    
    console.error("Usage: collect-data ORGANIZATION_NAME");
    
    console.error("Example: collect-data duckdb");
    process.exit(1);
  }

  
  console.log(`🚀 Collecting data for organization: ${org}`);

  const ghql = graphql.defaults({});

  await ensureDir(DATA_DIR);

  const reposCsv = fs.createWriteStream(path.join(DATA_DIR, "repos.csv"));
  const commitsCsv = fs.createWriteStream(path.join(DATA_DIR, "commits.csv"));
  const pullRequestsCsv = fs.createWriteStream(path.join(DATA_DIR, "pull_requests.csv"));
  const reviewsCsv = fs.createWriteStream(path.join(DATA_DIR, "reviews.csv"));

  await Promise.all([
    writeLine(reposCsv, CSV_HEADERS.repos + "\n"),
    writeLine(commitsCsv, CSV_HEADERS.commits + "\n"),
    writeLine(pullRequestsCsv, CSV_HEADERS.pullRequests + "\n"),
    writeLine(reviewsCsv, CSV_HEADERS.reviews + "\n"),
  ]);

  

  const repos = await getRepositories();
  const repoCount = repos.length;
  
  console.log(`✅ Found ${repoCount} repositories`);

  await Promise.all(repos.map((r) => writeLine(reposCsv, repoCsvRow(r))));

  let commitsCount = 0;
  let prCount = 0;
  let reviewsCount = 0;


  // sequential per-repo to reduce rate-limit risks and match bash pacing
  for (const [index, repo] of repos.entries()) {
    const repoName = repo.name;
    console.log(`📦 Processing repository ${index + 1}/${repoCount}: ${repoName}`);

    const empty = repo.isEmpty

    if (empty) {
      console.log(`  ⚠️  Repository ${repoName} has no commits (empty)`);
    } else {
      try {
        const commits = await listCommits(GITHUB_ORG, repo.name);
        for (const commit of commits) {
          await writeLine(commitsCsv, commitCsvRow(repoName, commit));
        }
        commitsCount += commits.length;
      } catch {
        console.log(`  ⚠️  Could not fetch commits for ${repoName} (permissions/rate limit?)`);
      }
    }

    try {
      const nodes = await getPullRequests(GITHUB_ORG, repo.name);
      const prLines = nodes.map((n) => n ? prCsvRow(repoName, n) : null).filter((x): x is string => Boolean(x));
      for (const line of prLines) {
        await writeLine(pullRequestsCsv, line);
      }
      prCount += prLines.length;

      const reviewLines = nodes.flatMap((node) => node ? reviewCsvRows(repoName, node) : []);
      await Promise.all(
        reviewLines.map((line) => writeLine(reviewsCsv, line))
      );
      reviewsCount += reviewLines.length;
    } catch {
      console.log(`  ⚠️  GraphQL request failed for ${repoName}`);
    }

    await sleep(SLEEP_BETWEEN_REPOS_MS);
  }

  await Promise.all([
    new Promise<void>((r) => reposCsv.end(r)),
    new Promise<void>((r) => commitsCsv.end(r)),
    new Promise<void>((r) => pullRequestsCsv.end(r)),
    new Promise<void>((r) => reviewsCsv.end(r)),
  ]);


  console.log("");
  console.log("✅ Data collection complete!");
  console.log("");
  console.log("📊 Data Summary:");
  console.log(`Repositories: ${repoCount}`);
  console.log(`Commits: ${commitsCount}`);
  console.log(`Pull Requests: ${prCount}`);
  console.log(`Reviews: ${reviewsCount}`);
  console.log("");
  console.log("📁 Generated files:");
  console.log("  - repos.csv");
  console.log("  - commits.csv");
  console.log("  - pull_requests.csv");
  console.log("  - reviews.csv");
  console.log("");
};

main().catch((err) => {
  
  console.error(err instanceof Error ? err.message : String(err));
  process.exit(1);
});
