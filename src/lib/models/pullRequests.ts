import type { PullRequest } from "../../services/github/resources/__generated__/types";
import { createCsvLine } from "../utils/csv.ts";

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

export const createPullRequestCsvLine = (repoName: string, pr: PullRequest) => {

  const assignees =
    pr.assignees?.nodes?.map((x) => (x ? x.login : null)).filter(Boolean).join(",") ?? "";
  const requested =
    pr.reviewRequests?.nodes
      ?.map((x) => (x?.requestedReviewer && "login" in x.requestedReviewer ? x.requestedReviewer.login : undefined))
      .filter(Boolean)
      .join(",") ?? "";
  const commentAuthors =
    pr.comments?.nodes?.map((x) => (x?.author ? x.author.login : null)).filter(Boolean).join(";") ?? "";


  return createCsvLine([
    repoName,
    pr.number,
    pr.title,
    pr.state,
    pr.author?.login ?? "",
    pr.createdAt,
    pr.mergedAt ?? "",
    pr.mergedBy?.login ?? "",
    assignees,
    requested,
    pr.comments?.totalCount ?? 0,
    pr.additions ?? 0,
    pr.deletions ?? 0,
    commentAuthors,
  ]);
};