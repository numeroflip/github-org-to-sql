import type { PullRequest } from "../../services/github/resources/__generated__/types";
import { createCsvLine } from "../utils/csv.ts";

export type ReviewRow = {
  repo_name: string;
  pr_number: number;
  reviewer: string;
  state: 'APPROVED' | 'CHANGES_REQUESTED' | 'COMMENTED' | 'DISMISSED';
  submitted_at: string;
};

export const REVIEWS_KEYS: (keyof ReviewRow)[] = [
  "repo_name",
  "pr_number",
  "reviewer",
  "state",
  "submitted_at",
] as const;

export const createReviewCsvLine = (repoName: string, pr: PullRequest) => {
  const prNumber = pr.number;
  const nodes = pr.reviews?.nodes ?? [];
  return nodes
    .map((review) =>
      review
        ? createCsvLine([
          repoName,
          prNumber,
          review.author?.login ?? "",
          review.state,
          review.submittedAt ?? ""
        ])
        : null
    )
    .filter((x): x is string => Boolean(x));

};