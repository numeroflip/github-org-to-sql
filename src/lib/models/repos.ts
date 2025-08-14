import { GITHUB_ORG } from "../../constants.ts";
import type { RepoData } from "../../services/github/resources/repo.ts";
import { createCsvLine } from "../utils/csv.ts";

export type RepoRow = {
  name: string;
  full_name: string;
  description: string;
  language: string;
  stargazers_count: number;
  forks_count: number;
  created_at: string;
  updated_at: string;
  url: string;
};

export const REPOS_KEYS: (keyof RepoRow)[] = [
  "name",
  "full_name",
  "description",
  "language",
  "stargazers_count",
  "forks_count",
  "created_at",
  "updated_at",
  "url",
] as const;


export const createRepoCsvLine = (r: RepoData): string => {
  return createCsvLine([
    r.name,
    `${GITHUB_ORG}/${r.name}`,
    r.description ?? "",
    r.primaryLanguage?.name ?? "",
    r.stargazerCount,
    r.forkCount,
    r.createdAt,
    r.updatedAt,
    r.url,
  ]);
};