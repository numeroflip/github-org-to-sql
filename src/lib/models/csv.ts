import { createCsvHeader } from "../utils/csv.ts";
import { COMMITS_KEYS } from "./commits.ts";
import { PR_KEYS } from "./pullRequests.ts";
import { REPOS_KEYS } from "./repos.ts";
import { REVIEWS_KEYS } from "./reviews.ts";

export const CSV_HEADERS = {
  repos: createCsvHeader(REPOS_KEYS),
  commits: createCsvHeader(COMMITS_KEYS),
  pullRequests: createCsvHeader(PR_KEYS),
  reviews: createCsvHeader(REVIEWS_KEYS),
};