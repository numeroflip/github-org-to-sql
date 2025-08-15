import type { Commit } from "../../services/github/resources/__generated__/types.ts";
import type { CommitItem } from "../../services/github/types.ts";
import { createCsvLine } from "../utils/csv.ts";

export type CommitRow = {
  repo_name: string;
  sha: string;
  author_email: string;
  committer_email: string;
  message: string;
  date: string;
};

export const COMMITS_KEYS: (keyof CommitRow)[] = [
  "repo_name",
  "sha",
  "author_email",
  "committer_email",
  "message",
  "date",
] as const;

export const createCommitCsvLine = (repoName: string, commit: Commit) => {
  return createCsvLine([
    repoName,
    commit.oid,
    commit.author?.email ?? "", // Git author email
    commit.committer?.email ?? "", // Git committer email 
    commit.message ?? "",
    commit.committedDate ?? "",
  ]);
};