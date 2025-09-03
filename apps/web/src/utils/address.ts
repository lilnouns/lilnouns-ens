/**
 * Shortens an Ethereum address by displaying only the first and last few characters
 * @param address - The Ethereum address to shorten
 * @param chars - Number of characters to show at the beginning and end
 * @returns The shortened address string
 */
import type { NonEmptyString } from "type-fest";

export const shortenAddress = (
  address: string,
  chars = 4,
): "" | NonEmptyString => {
  if (!address) return "";
  return `${address.slice(0, Math.max(0, chars + 2))}...${address.slice(Math.max(0, address.length - chars))}` as NonEmptyString;
};
