import fs from "fs";
import path from "path";
import { GITHUB_ORG } from "./constants.ts";
import { CSV_HEADERS } from "./lib/models/csv.ts";
import { createPullRequestCsvLine } from "./lib/models/pullRequests.ts";
import { createRepoCsvLine } from "./lib/models/repos.ts";
import { createReviewCsvLine } from "./lib/models/reviews.ts";
import { createCommitCsvLine } from "./lib/models/commits.ts";
import { createUserCsvLine, UserRegistry } from "./lib/models/users.ts";
import { getCommits } from "./services/github/resources/commits.ts";
import { getPullRequests } from "./services/github/resources/pullRequest.ts";
import { getRepositories } from "./services/github/resources/repo.ts";
import { ensureDir } from "./lib/utils/ensureDir.ts";
import { writeLine } from "./lib/utils/writeLine.ts";
import { sleep } from "./lib/utils/sleep.ts";

const DATA_DIR = "data";
const SLEEP_BETWEEN_REPOS_MS = 500;

const main = async () => {
  const org = GITHUB_ORG;

  console.log(`🚀 Collecting data for organization: ${org}`);

  /**
   * INITIALIZE USER REGISTRY
   */
  const userRegistry = new UserRegistry();

  /**
   * INITIALIZE CSV FILES
   */
  await ensureDir(DATA_DIR);

  const reposCsv = fs.createWriteStream(path.join(DATA_DIR, "repos.csv"));
  const commitsCsv = fs.createWriteStream(path.join(DATA_DIR, "commits.csv"));
  const pullRequestsCsv = fs.createWriteStream(path.join(DATA_DIR, "pull_requests.csv"));
  const reviewsCsv = fs.createWriteStream(path.join(DATA_DIR, "reviews.csv"));
  const usersCsv = fs.createWriteStream(path.join(DATA_DIR, "users.csv"));

  await Promise.all([
    writeLine(reposCsv, CSV_HEADERS.repos + "\n"),
    writeLine(commitsCsv, CSV_HEADERS.commits + "\n"),
    writeLine(pullRequestsCsv, CSV_HEADERS.pullRequests + "\n"),
    writeLine(reviewsCsv, CSV_HEADERS.reviews + "\n"),
    writeLine(usersCsv, CSV_HEADERS.users + "\n"),
  ]);

  /**
   * GET REPOSITORIES
   */

  const repos = await getRepositories();
  const repoCount = repos.length;

  console.log(`✅ Found ${repoCount} repositories`);

  // Write repos data
  for (const repo of repos) {
    await writeLine(reposCsv, createRepoCsvLine(repo));
  }

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
          // Register users from commit data
          const authorEmail = commit.author?.email;
          const authorName = commit.author?.name;
          const committerEmail = commit.committer?.email;
          const committerName = commit.committer?.name;

          if (authorEmail) {
            userRegistry.registerFromCommit(authorEmail, authorName || '');
          }
          if (committerEmail && committerEmail !== authorEmail) {
            userRegistry.registerFromCommit(committerEmail, committerName || '');
          }

          // Write commit with just emails
          await writeLine(commitsCsv, createCommitCsvLine(repoName, commit));
        }
        commitsCount += commits.length;
      } catch (e) {
        console.log(`  ⚠️  Could not fetch commits for ${repoName} (permissions/rate limit?). Error: ${e instanceof Error ? e.message : 'Unknown error'}`);
      }
    }

    /**
     * GET PULL REQUESTS
     */
    try {
      const nodes = await getPullRequests(GITHUB_ORG, repo.name);

      // Process PRs with UserRegistry (async)
      for (const node of nodes) {
        if (node) {
          const prLine = await createPullRequestCsvLine(repoName, node, userRegistry);
          await writeLine(pullRequestsCsv, prLine);
          prCount++;
        }
      }

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
   * WRITE USERS DATA
   */
  console.log(`👥 Writing deduplicated users data...`);
  const users = userRegistry.exportUsers();
  for (const user of users) {
    await writeLine(usersCsv, createUserCsvLine(user));
  }

  /**
   * CLOSE CSV FILES
   */
  await Promise.all([
    new Promise<void>((r) => reposCsv.end(r)),
    new Promise<void>((r) => commitsCsv.end(r)),
    new Promise<void>((r) => pullRequestsCsv.end(r)),
    new Promise<void>((r) => reviewsCsv.end(r)),
    new Promise<void>((r) => usersCsv.end(r)),
  ]);

  const userCount = users.length;

  console.log("");
  console.log("✅ Data collection complete!");
  console.log("");
  console.log("📊 Data Summary:");
  console.log(`Repositories: ${repoCount}`);
  console.log(`Commits: ${commitsCount}`);
  console.log(`Pull Requests: ${prCount}`);
  console.log(`Reviews: ${reviewsCount}`);
  console.log(`Users: ${userCount}`);
  console.log(`  - GitHub users: ${users.filter(u => u.github_login).length}`);
  console.log(`  - External contributors: ${users.filter(u => !u.github_login).length}`);
};

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

main().catch(console.error);
