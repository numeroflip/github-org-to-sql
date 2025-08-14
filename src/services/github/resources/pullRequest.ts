import { github } from "../client.ts";
import { paginate } from "../utils/paginate.ts";
import type { PullRequest, Repository } from "./__generated__/types";

export const getPullRequests = async (owner: string, repo: string): Promise<PullRequest[]> => {
  try {
    return await paginate(async (cursor: string | null) => {
      const response = await github.graphql<{ repository: Repository }>(`
        query GetPullRequests($owner: String!, $name: String!, $num: Int = 50, $cursor: String) {
      repository(owner: $owner, name: $name) {
        pullRequests(first: $num, after: $cursor, states: [OPEN, CLOSED, MERGED]) {
          pageInfo {
            hasNextPage
            endCursor
            }
          nodes {
            number
            title
            state
            author {
              login
              }
              createdAt
            mergedAt
            mergedBy {
              login
            }
            assignees(first: 10) {
              nodes {
                login
                }
            }
            reviewRequests(first: 10) {
              nodes {
                requestedReviewer {
                  ... on User {
                    login
                  }
                }
              }
              }
              reviews(first: 100) {
                totalCount
                nodes {
                  author {
                  login
                  }
                  state
                  submittedAt
                  }
                  }
            comments(first: 100) {
              totalCount
              nodes {
                author {
                  login
                }
              }
              }
            additions
            deletions
            }
        }
      }
    }`, {
        owner,
        name: repo,
        cursor
      });

      const pullRequests = response?.repository?.pullRequests?.nodes ?? [];

      const pageInfo = {
        hasNextPage: response?.repository?.pullRequests?.pageInfo?.hasNextPage ?? false,
        endCursor: response?.repository?.pullRequests?.pageInfo?.endCursor ?? null
      }
      return {
        data: pullRequests.filter(Boolean) as PullRequest[],
        pageInfo
      };
    });
  } catch (e) {
    console.error(e);
    return [];
  }
};