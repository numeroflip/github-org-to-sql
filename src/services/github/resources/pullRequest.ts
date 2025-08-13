import { github } from "../client.ts";
import type { PaginationParams } from "../types.ts";
import type { PullRequest, Repository } from "./__generated__/types";



export const getPullRequests = async (owner: string, repo: string): Promise<PullRequest[]> => {
  console.log('Getting pull requests for', owner, repo,);
try {

  const response = await github.graphql<{repository: Repository}>(`
    query GetPullRequests($owner: String!, $name: String!, $num: Int = 100, $cursor: String) {
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
        assignees(first: 5) {
          nodes {
            login
            }
        }
        reviewRequests(first: 5) {
          nodes {
            requestedReviewer {
              ... on User {
                login
              }
            }
          }
          }
          reviews(first: 50) {
            totalCount
            nodes {
              author {
              login
              }
              state
              submittedAt
              }
              }
        comments(first: 50) {
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
});
  const pullRequests = response?.repository?.pullRequests?.nodes ?? [];
  return pullRequests.filter(Boolean) as PullRequest[];
} catch (e) {
  
  console.error(e);
  return [];
}

};
