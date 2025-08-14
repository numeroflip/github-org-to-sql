import type { CommitItem } from "../../services/github/types.ts";
import { createCsvLine } from "../utils/csv.ts";

export type CommitRow = {
  repo_name: string;
  sha: string;
  author_login: string;
  committer_login: string;
  message: string;
  date: string;
};

export const COMMITS_KEYS: (keyof CommitRow)[] = [
  "repo_name",
  "sha",
  "author_login",
  "committer_login",
  "message",
  "date",
] as const;

export const createCommitCsvLine = (repoName: string, commit: CommitItem) => {
  return createCsvLine([
    repoName,
    commit.sha,
    commit.commit.author?.name ?? "",
    commit.commit.committer?.name ?? "",
    commit.commit.message ?? "",
    commit.commit.author?.date ?? "",
  ]);
};