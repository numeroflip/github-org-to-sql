export type PullRequestRow = {
  repo_name: string;
  number: number;
  title: string;
  state: string;
  author: string;
  created_at: string;
  merged_at: string;
  merged_by: string;
  assignees: string;
  requested_reviewers: string;
  comments: number;
  additions: number;
  deletions: number;
  comment_authors: string;
};

export const PR_KEYS: (keyof PullRequestRow)[] = [
  "repo_name",
  "number",
  "title",
  "state",
  "author",
  "created_at",
  "merged_at",
  "merged_by",
  "assignees",
  "requested_reviewers",
  "comments",
  "additions",
  "deletions",
  "comment_authors",
] as const; 