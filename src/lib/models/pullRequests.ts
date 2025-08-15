import type { PullRequest } from "../../services/github/resources/__generated__/types";
import { createCsvLine } from "../utils/csv.ts";
import type { UserRegistry } from "./users.ts";

export type PullRequestRow = {
  repo_name: string;
  number: number;
  title: string;
  state: string;
  author_email: string;          // Changed from author login to email
  created_at: string;
  merged_at: string;
  merged_by_email: string;       // Changed from merged_by login to email
  assignee_emails: string;       // Changed from assignees to emails (semicolon-separated)
  requested_reviewer_emails: string; // Changed from requested_reviewers to emails
  comments: number;
  additions: number;
  deletions: number;
  comment_author_emails: string; // Changed from comment_authors to emails
};

export const PR_KEYS: (keyof PullRequestRow)[] = [
  "repo_name",
  "number",
  "title",
  "state",
  "author_email",
  "created_at",
  "merged_at",
  "merged_by_email",
  "assignee_emails",
  "requested_reviewer_emails",
  "comments",
  "additions",
  "deletions",
  "comment_author_emails",
] as const;

export const createPullRequestCsvLine = async (
  repoName: string,
  pr: PullRequest,
  userRegistry: UserRegistry
) => {
  // Convert GitHub logins to emails via UserRegistry
  const authorEmail = pr.author?.login
    ? await userRegistry.registerFromGithubLogin(pr.author.login)
    : "";

  const mergedByEmail = pr.mergedBy?.login
    ? await userRegistry.registerFromGithubLogin(pr.mergedBy.login)
    : "";

  // Convert assignees (array of logins) to emails
  const assigneeEmails: string[] = [];
  if (pr.assignees?.nodes) {
    for (const assignee of pr.assignees.nodes) {
      if (assignee?.login) {
        const email = await userRegistry.registerFromGithubLogin(assignee.login);
        if (email) assigneeEmails.push(email);
      }
    }
  }

  // Convert requested reviewers to emails
  const reviewerEmails: string[] = [];
  if (pr.reviewRequests?.nodes) {
    for (const request of pr.reviewRequests.nodes) {
      if (request?.requestedReviewer && "login" in request.requestedReviewer) {
        const email = await userRegistry.registerFromGithubLogin(request.requestedReviewer.login);
        if (email) reviewerEmails.push(email);
      }
    }
  }

  // Convert comment authors to emails
  const commentAuthorEmails: string[] = [];
  if (pr.comments?.nodes) {
    for (const comment of pr.comments.nodes) {
      if (comment?.author?.login) {
        const email = await userRegistry.registerFromGithubLogin(comment.author.login);
        if (email) commentAuthorEmails.push(email);
      }
    }
  }

  return createCsvLine([
    repoName,
    pr.number,
    pr.title,
    pr.state,
    authorEmail || "",
    pr.createdAt,
    pr.mergedAt ?? "",
    mergedByEmail || "",
    assigneeEmails.join("; "),
    reviewerEmails.join("; "),
    pr.comments?.totalCount ?? 0,
    pr.additions ?? 0,
    pr.deletions ?? 0,
    Array.from(new Set(commentAuthorEmails)).join("; "), // Dedupe comment authors
  ]);
};