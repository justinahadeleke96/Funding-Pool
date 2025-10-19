🧬 Decentralized Research Funding Pool (Clarity Smart Contract)
Overview

This Clarity smart contract implements a decentralized research funding system where scientists can submit research proposals, and token holders vote to decide which projects receive grants. It aims to promote transparent, community-driven funding of scientific innovation using blockchain governance.

🚀 Key Features

Proposal Submission

Scientists can submit proposals including a title, description, and requested funding amount.

Each proposal is assigned a unique proposal-id.

Voting Mechanism

Token holders vote for or against a proposal.

Each voter’s influence is proportional to their token balance.

Votes are recorded to prevent double voting.

Funding Execution

After the voting period, approved proposals (those with more “for” votes) can be executed.

Execution transfers the proposed funding amount from the contract to the scientist’s wallet.

Token Minting

The contract owner can mint governance tokens for participants.

These tokens represent voting power in the ecosystem.

STX Funding Pool

Users can deposit STX tokens into the contract to build the research grant pool.

The contract’s STX balance can be queried anytime.

Built-in Safeguards

Input validation prevents empty titles/descriptions or zero funding.

Prevents double voting or executing already-funded proposals.

Checks for expired voting windows before execution.

🧩 Data Structures
Type	Name	Purpose
Data-var	next-proposal-id	Tracks ID for next proposal
Data-var	voting-period	Defines proposal voting duration in blocks
Map	proposals	Stores all submitted proposals
Map	votes	Tracks votes per proposal and voter
Map	token-balances	Records token balances for voting power
🔍 Read-only Functions
Function	Description
get-proposal(proposal-id)	Returns details of a proposal
get-vote(proposal-id, voter)	Checks if a voter has voted on a proposal
get-token-balance(holder)	Returns holder’s voting token balance
get-next-proposal-id()	Returns next available proposal ID
get-voting-period()	Returns the current voting period
get-contract-balance()	Returns the STX balance of the contract
⚙️ Public Functions
Function	Description
submit-proposal(title, description, funding-amount)	Scientist submits a proposal
vote-on-proposal(proposal-id, vote)	Token holder votes on a proposal
execute-proposal(proposal-id)	Executes a winning proposal and transfers funds
mint-tokens(recipient, amount)	Contract owner mints governance tokens
deposit-funds(amount)	Deposits STX into the funding pool
🧠 Logic Summary

Proposal Lifecycle

Starts with submission → voting → (if approved) execution.

Voting

Weighted by tokens; each holder can vote once per proposal.

Execution

Allowed only if voting period has ended and the proposal is approved.

Governance Tokens

Control who can vote and how much influence they have.

🧪 Example Flow

Contract owner deposits STX into the funding pool.

Owner mints tokens to community members.

A scientist submits a proposal requesting funding.

Token holders vote using vote-on-proposal.

After voting ends, if approved, the contract transfers STX to the scientist using execute-proposal.

🔐 Error Codes
Error	Code	Meaning
ERR-NOT-AUTHORIZED	u100	Sender not authorized
ERR-PROPOSAL-NOT-FOUND	u101	Proposal ID invalid
ERR-ALREADY-VOTED	u102	Voter already cast a vote
ERR-VOTING-ENDED	u103	Voting period has ended
ERR-INSUFFICIENT-BALANCE	u104	Voter lacks tokens
ERR-PROPOSAL-ALREADY-EXECUTED	u105	Proposal already funded
ERR-INVALID-INPUT	u106	Invalid function input
🧾 Notes

The voting-period defaults to 1440 blocks (~10 days).

All token and STX transfers are handled via built-in Clarity primitives (stx-transfer?, map-set, etc.).

The contract owner is the deployer (set via CONTRACT-OWNER constant).