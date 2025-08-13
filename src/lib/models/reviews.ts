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