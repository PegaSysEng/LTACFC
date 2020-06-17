/*
 * Copyright 2020 ConsenSys AG.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity >=0.6.9;


/**
 * Registrar contracts hold the public keys used to verify transaction roots from blockchains.
 *
 * A set of addresses are administrators for the contract. The administrators vote to add
 * other administrators, remove administrators, change the voting contract, add blockchains,
 * and add and remove public keys. The account that deploys the contract is the initial
 * administrator.
 *
 * When the contract is first deployed there is no voting contract. In this mode of operation,
 * all proposed votes are immediately acted upon. That is, there is no voting. When a voting
 * algorithm is in place the voting has the following process:
 *
 * proposeVote: An administrator proposes a vote. The address is deemed to have voted for the proposal.
 * vote: During the voting period all administrators can vote for or against the proposal.
 * actionVote: At any point after the voting period, any administrator can call this function to enact the vote.
 *
 * The only signature algorithm supported in this version are ECDSA / KECCAK256 using secp256k1 curve.
 * Public keys are represented as addresses. Implementer are strongly suggested to use a separate key
 * pair for each blockchain and in particular not to use a transaction root signing key pair for
 * Ethereum transaction signing. The reasons for this are: reduce the impact caused by a compromised
 * private key, different key roll-over schedules, differing security requirements around the storage
 * and operation of the private keys, given the differing usages.
 *
 */
interface RegistrarInterface {
    /**
     * Propose that a certain action be voted on.
     *
     * Proposals are actioned immediately if there is no voting algorithm at the contract level for contract
     * level actions, and for a blockchain for blockchain specific actions.
     *
     * Proposer must be an admin at the contract or for a blockchain to propose a vote.
     *
     * When an account proposes a vote, it automatically votes for the vote. That is, the proposer does
     * not need to separately call the vote function.
     *
     * Types of votes:
     *
     * Value  Action                                  Target                        Additional Information
     * 1      Add an admin                            Address of admin to add       ignored
     *         Revert if the address is already an admin.
     * 2      Remove an admin                         Address of admin to remove    ignored
     *         Revert if the address is not an admin.
     * 3      Change voting algorithm & voting period Address of voting contract    Voting period
     *         Proposing a voting algorithm with address(0) removes the voting algorithm.
     *         The voting period must be greater than 1.
     * 4      Add a blockchain                        Blockchain Id                 Signing algorithm used for blockchain.
     *         The blockchain must not exist yet. The signing algorithm must be valid.
     * 5     Change signing threshold                 Blockchain Id                 Signing threshold
     *         The signing threshold must be 1 or more.
     * 6     Add signer                              Blockchain Id                  Address corresponding to public key of signer.
     * 7     Remove signer                           Blockchain Id                  Address corresponding to public key of signer.
     *
     * @param _action         The type of vote
     * @param _voteTarget     What is being voted on
     * @param _additionalInfo Additional information as per the table above.
     */
    function proposeVote(uint16 _action, uint256 _voteTarget, uint256 _additionalInfo) external;

    /**
     * Vote for a proposal.
     *
     * If an account has already voted, they can not vote again or change their vote.
     * Voters must be an admin at the contract or for a blockchain.
     *
     * @param _action The type of vote.
     * @param _voteTarget What is being voted on
     * @param _voteFor True if the transaction sender wishes to vote for the action.
     */
    function vote(uint16 _action, uint256 _voteTarget, bool _voteFor) external;

    /**
     * Action votes to affect the change.
     *
     * Only admins can action votes.
     *
     * @param _voteTarget What is being voted on.
     */
    function actionVotes(uint256 _voteTarget) external;


    /**
     * Verify signatures.
     *
     * Revert if:
     * - The number of signers and signature components does not match
     * - If any of the signers are not signers for the blockchain
     * - If any of the signatures do not verify
     */
    function verify(
        uint256 _blockchainId,
        address[] calldata _signers,
        bytes32[] calldata _sigR,
        bytes32[] calldata _sigS,
        uint8[] calldata _sigV,
        bytes calldata _plainText) external;


    function adminArraySize() external view returns (uint256);

    function getAdmin(uint256 _index) external view returns (address);

    function isAdmin(address _mightBeAdmin) external view returns (bool);

    function getNumAdmins() external view returns (uint64);

    function getSigAlgorithm(uint256 _blockchainId) external view returns (uint256);

    function getSigningThreshold(uint256 _blockchainId) external view returns (uint64);

    function numSigners(uint256 _blockchainId) external view returns (uint64);

    function isSigner(uint256 _blockchainId, address _mightBeSigner) external view returns (bool);


    /*
     * Return the implementation version.
     */
    function getApiVersion() external pure returns (uint16);


    event Voted(address _participant, uint16 _action, uint256 _voteTarget, bool _votedFor);
    event VoteResult(uint16 _action, uint256 _voteTarget, bool _result);

}