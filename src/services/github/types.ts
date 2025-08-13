import type { RestEndpointMethodTypes } from "@octokit/rest";

export type RepoListItem = RestEndpointMethodTypes["repos"]["listForOrg"]["response"]["data"][number];
export type CommitItem = RestEndpointMethodTypes["repos"]["listCommits"]["response"]["data"][number];
export type PaginationParams = {
  num: number;
  cursor: string | null;
}