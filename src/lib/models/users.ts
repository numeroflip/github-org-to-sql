import { createCsvLine } from "../utils/csv.ts";
import { github } from "../../services/github/client.ts";

export type UserRow = {
  email: string;                // Primary key
  primary_name: string;         // Most common/recent name  
  github_login: string | null;  // GitHub username (if known)
  all_names: string;            // All name variations (semicolon-separated)
};

export const USERS_KEYS: (keyof UserRow)[] = [
  "email",
  "primary_name",
  "github_login",
  "all_names",
] as const;

export const createUserCsvLine = (user: UserRow) => {
  return createCsvLine([
    user.email,
    user.primary_name,
    user.github_login || "",
    user.all_names,
  ]);
};

/**
 * In-memory registry to collect and deduplicate users during data collection
 */
export class UserRegistry {
  private users = new Map<string, UserData>();
  private githubLoginToEmail = new Map<string, string>();
  private emailCache = new Map<string, string>(); // Cache API responses

  registerFromCommit(email: string | null, name: string, login?: string) {
    if (login) {
      this.registerFromGithubLogin(login);
    }

    if (!email) return;

    const user = this.getOrCreateUser(email);
    user.addName(name);

  }

  async registerFromGithubLogin(githubLogin: string): Promise<string | null> {
    if (!githubLogin) return null;

    // Check if we already have this GitHub login mapped
    const existingEmail = this.githubLoginToEmail.get(githubLogin);
    if (existingEmail) {
      return existingEmail;
    }

    // Fetch email from GitHub API
    const email = await this.fetchEmailForGithubLogin(githubLogin);
    if (!email) return null;

    const user = this.getOrCreateUser(email);
    user.github_login = githubLogin;
    user.addName(githubLogin); // Fallback name

    this.githubLoginToEmail.set(githubLogin, email);
    return email;
  }

  private getOrCreateUser(email: string): UserData {
    if (!this.users.has(email)) {
      this.users.set(email, new UserData(email));
    }
    return this.users.get(email)!;
  }

  private async fetchEmailForGithubLogin(githubLogin: string): Promise<string | null> {
    // Check cache first
    if (this.emailCache.has(githubLogin)) {
      return this.emailCache.get(githubLogin)!;
    }

    try {
      const response = await github.rest.users.getByUsername({
        username: githubLogin,
      });

      const email = response.data.email || `${githubLogin}@users.noreply.github.com`;

      // Cache the result
      this.emailCache.set(githubLogin, email);

      return email;
    } catch (error) {
      console.warn(`Could not fetch email for ${githubLogin}:`, error instanceof Error ? error.message : error);

      // Fallback to noreply email
      const fallbackEmail = `${githubLogin}@users.noreply.github.com`;
      this.emailCache.set(githubLogin, fallbackEmail);

      return fallbackEmail;
    }
  }

  exportUsers(): UserRow[] {
    return Array.from(this.users.values()).map(user => user.toRow());
  }
}

class UserData {
  email: string;
  names = new Set<string>();
  github_login: string | null = null;

  constructor(email: string) {
    this.email = email;
  }

  addName(name: string) {
    if (name) this.names.add(name);
  }

  toRow(): UserRow {
    const allNames = Array.from(this.names);
    return {
      email: this.email,
      primary_name: this.getPrimaryName(),
      github_login: this.github_login,
      all_names: allNames.join('; '),
    };
  }

  private getPrimaryName(): string {
    if (this.names.size === 0) return this.github_login || 'Unknown';

    // Prefer longer names (usually more complete)
    return Array.from(this.names).reduce((longest, current) =>
      current.length > longest.length ? current : longest
    );
  }
} 