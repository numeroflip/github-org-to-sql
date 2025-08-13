import { GITHUB_ORG } from "../../../constants.ts";
import { github } from "../client.ts";
import type { Repository } from "./__generated__/types";


export const getRepositories = async () => {

  const response = await github.graphql<RepoResponse>(`
    query allRepositories($org: String!) {
      organization(login: $org) {
        repositories(first: 100) {
          nodes {
            name
            description
            primaryLanguage {
              name
            }
            stargazerCount
            forkCount
            createdAt
            updatedAt
            isEmpty
            url
            isArchived
            isFork
            isMirror
            isPrivate
            isTemplate
            isLocked
          }
        }
      }
    }
    `, {
    org: GITHUB_ORG,
  });

  const repos = response.organization.repositories.nodes;

  return repos;
};

export type RepoData = Pick<Repository, "name" | "forkCount" | "createdAt" | "updatedAt" | "stargazerCount" | "primaryLanguage" | "description" | "isEmpty"  | "url" | "isArchived" | "isFork" | "isMirror" | "isPrivate" | "isTemplate" | "isLocked"> 

type RepoResponse = {
  organization: {
    repositories: {
      nodes: RepoData[];
    };
  };
};







