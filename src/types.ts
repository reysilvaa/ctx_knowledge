export interface KnowledgeFact {
  category?: string;
  key?: string;
  value?: string;
  created_at?: string;
}

export interface KnowledgePayload {
  project_root?: string;
  project_hash?: string;
  facts: KnowledgeFact[];
  patterns?: unknown[];
  history?: unknown[];
  updated_at?: string;
  judged_pairs?: unknown[];
  [key: string]: unknown;
}

export interface SyncRecord {
  project_id: string;
  project_hash: string;
  payload: KnowledgePayload;
  updated_at: string;
}

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
}
