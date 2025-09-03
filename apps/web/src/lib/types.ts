import type { NonEmptyString } from 'type-fest';

export interface OwnedNft {
  image: NonEmptyString<string>;
  name?: NonEmptyString<string>;
  tokenId: NonEmptyString<string>;
}
