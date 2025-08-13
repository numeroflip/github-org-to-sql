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