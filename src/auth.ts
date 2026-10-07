export function authenticate(authHeader: string | undefined): boolean {
  const secret = process.env.CTX_SECRET_KEY;
  if (!secret) {
    throw new Error("Missing CTX_SECRET_KEY environment variable");
  }

  if (!authHeader) return false;
  const parts = authHeader.split(" ");
  if (parts.length !== 2 || parts[0].toLowerCase() !== "bearer") {
    return false;
  }

  return parts[1] === secret;
}
