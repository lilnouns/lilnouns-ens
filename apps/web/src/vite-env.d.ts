/* eslint-disable unicorn/prevent-abbreviations */
/// <reference types="vite/client" />

interface ImportMeta {
  readonly env: ImportMetaEnv;
}

interface ImportMetaEnv {
  readonly VITE_CHAIN_ID?: string;
  readonly VITE_CHAIN_NAME?: string;
  readonly VITE_FC_BUTTON?: string;
  readonly VITE_FC_IMAGE?: string;
  readonly VITE_FC_LAUNCH_URL?: string;
  readonly VITE_FC_SPLASH_BG?: string;
  readonly VITE_FC_SPLASH_ICON?: string;
  readonly VITE_OG_IMAGE?: string;
  readonly VITE_RPC_HTTP_URL?: string;
  readonly VITE_SITE_DESCRIPTION?: string;
  readonly VITE_SITE_TITLE?: string;
  readonly VITE_SITE_URL?: string;
  readonly VITE_SUBGRAPH_URL?: string;
  readonly VITE_WC_PROJECT_ID?: string;
}
