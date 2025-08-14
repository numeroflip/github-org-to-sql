import { GITHUB_ORG } from "../../../constants.ts";
import { github } from "../client.ts";
import { paginate } from "../utils/paginate.ts";
import type { Organization, Repository } from "./__generated__/types";


export const getRepositories = async () => {

  const response = paginate(async (cursor) => {
    const response = await github.graphql<{ organization: Organization }>(`
    query allRepositories($org: String!, $cursor: String) {
      organization(login: $org) {
        repositories(first: 50, after: $cursor) {
          pageInfo {
            hasNextPage
            endCursor
          }
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
      cursor
    });

    const repos = response.organization.repositories.nodes;

    const pageInfo = {
      hasNextPage: response.organization.repositories.pageInfo?.hasNextPage ?? false,
      endCursor: response.organization.repositories.pageInfo?.endCursor ?? null
    }

    return {
      data: repos ? repos.filter(Boolean) as Repository[] : [],
      pageInfo
    }
  });

  return response;
};







