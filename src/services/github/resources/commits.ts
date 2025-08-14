import { github } from "../client.ts";
import type { CommitItem } from "../types";

const COMMITS_PER_PAGE = 100;

export const getCommits = async (
  owner: string,
  repo: string
): Promise<CommitItem[]> => {
  return github.paginate(github.rest.repos.listCommits, {
    owner,
    repo,
    per_page: COMMITS_PER_PAGE,
  });
};


