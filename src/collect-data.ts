import fs from "fs";
import path from "path";
import { GITHUB_ORG } from "./constants.ts";
import { CSV_HEADERS } from "./lib/models/csv.ts";
import { createPullRequestCsvLine } from "./lib/models/pullRequests.ts";
import { createRepoCsvLine } from "./lib/models/repos.ts";
import { createReviewCsvLine } from "./lib/models/reviews.ts";
import { getCommits } from "./services/github/resources/commits.ts";
import { getPullRequests } from "./services/github/resources/pullRequest.ts";
import { getRepositories } from "./services/github/resources/repo.ts";
import { ensureDir } from "./lib/utils/ensureDir.ts";
import { writeLine } from "./lib/utils/writeLine.ts";
import { sleep } from "./lib/utils/sleep.ts";
import { createCommitCsvLine } from "./lib/models/commits.ts";

const DATA_DIR = "data";
const SLEEP_BETWEEN_REPOS_MS = 500;

const main = async () => {
  const org = GITHUB_ORG;

  console.log(`🚀 Collecting data for organization: ${org}`);

  /**
   * INITIALIZE CSV FILES
   */
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

  /**
   * GET REPOSITORIES
   */

  const repos = await getRepositories();
  const repoCount = repos.length;

  console.log(`✅ Found ${repoCount} repositories`);

  await Promise.all(repos.map((repo) => writeLine(reposCsv, createRepoCsvLine(repo))));

  let commitsCount = 0;
  let prCount = 0;
  let reviewsCount = 0;


  /**
   * PROCESS REPOSITORIES
   * 
   * Sequential per-repo to reduce rate-limit risks
   */
  for (const [index, repo] of repos.entries()) {
    const repoName = repo.name;
    console.log(`📦 Processing repository ${index + 1}/${repoCount}: ${repoName}`);

    const empty = repo.isEmpty

    if (empty) {
      console.log(`  ⚠️  Repository ${repoName} has no commits (empty)`);
    } else {
      try {
        const commits = await getCommits(GITHUB_ORG, repo.name);
        for (const commit of commits) {
          await writeLine(commitsCsv, createCommitCsvLine(repoName, commit));
        }
        commitsCount += commits.length;
      } catch {
        console.log(`  ⚠️  Could not fetch commits for ${repoName} (permissions/rate limit?)`);
      }
    }

    /**
     * GET PULL REQUESTS
     */
    try {
      const nodes = await getPullRequests(GITHUB_ORG, repo.name);
      const prLines = nodes.map((n) => n ? createPullRequestCsvLine(repoName, n) : null).filter((x): x is string => Boolean(x));

      for (const line of prLines) {
        await writeLine(pullRequestsCsv, line);
      }
      prCount += prLines.length;


      const reviewLines = nodes.flatMap((node) => node ? createReviewCsvLine(repoName, node) : []);
      await Promise.all(
        reviewLines.map((line) => writeLine(reviewsCsv, line))
      );
      reviewsCount += reviewLines.length;
    } catch {
      console.log(`  ⚠️  GraphQL request failed for ${repoName}`);
    }

    await sleep(SLEEP_BETWEEN_REPOS_MS);
  }


  /**
   * CLOSE CSV FILES
   */
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
