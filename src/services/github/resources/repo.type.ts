import type { RestEndpointMethodTypes } from "@octokit/rest";

export type RepoListItem = RestEndpointMethodTypes["repos"]["listForOrg"]["response"]["data"][number];


type Response = {
  organization: {
    repositories: {
      nodes: {
        name: string;
        description: string;
        isEmpty: boolean;
        url: string;
        isArchived: boolean;
        isFork: boolean;
        isMirror: boolean;
        isPrivate: boolean;
        isTemplate: boolean;
        isLocked: boolean;
      }[];
    };
  };
};
