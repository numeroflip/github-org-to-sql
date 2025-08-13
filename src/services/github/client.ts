import { Octokit as RestOctokit } from "@octokit/rest";
import { paginateGraphQL } from "@octokit/plugin-paginate-graphql";

const MyOctokit = RestOctokit.plugin(paginateGraphQL);

const token = getToken();
export const github = new MyOctokit({ auth: token });

function getToken(): string {
  const t = process.env.GITHUB_TOKEN ?? process.env.GH_TOKEN ?? "";
  if (!t) {
    throw new Error("GITHUB_TOKEN (or GH_TOKEN) must be set in the environment.");
  }
  return t;
};  