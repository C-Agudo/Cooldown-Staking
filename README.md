# cooldown-staking

## 1. Problem Statement

Staking-based protocols rely on _bonded capital_ to secure state, coordination, or economic guarantees. A fundamental risk in these systems is **instant exit**: participants can withdraw capital immediately after performing adversarial or risky actions, escaping accountability.

This project implements a **protocol-level cooldown mechanism** that enforces a _mandatory delay_ between a participant’s intent to exit staking and the effective withdrawal of bonded capital.

The goal is **not yield generation**, liquidity optimization, or UX, but to model how **time, state, and incentives** interact to protect protocol safety.

---

## 2. System Model

### 2.1 Actors / Roles

- **Participant**: an entity that bonds capital to the protocol.
- **Exiting Participant**: a participant who has declared intent to exit and is subject to a cooldown.
- **Protocol**: enforces time-based rules and manages the state machine of participants.

### 2.2 State Variables

- `userBalance`: amount of ERC-20 tokens bonded by each participant.
- `participantState`: enum representing `UNBONDED`, `BONDED`, `EXIT_PENDING`, `EXIT_READY`.
- `exitTimestamp`: timestamp when participant declared exit.
- `cooldownPeriod`: system-defined delay between exit declaration and withdrawal.
- `totalBonded`: total bonded capital in the protocol.

### 2.3 Actions / State Transitions

| Function        | From State | To State     | Condition                                      |
| --------------- | ---------- | ------------ | ---------------------------------------------- |
| `bond(amount)`  | UNBONDED   | BONDED       | Participant must not already be bonded         |
| `declareExit()` | BONDED     | EXIT_PENDING | Exit not already declared                      |
| `withdraw()`    | EXIT_READY | UNBONDED     | Current time >= exitTimestamp + cooldownPeriod |

### 2.4 Time Constraints

- `cooldownPeriod` ensures that exits cannot occur instantly.
- All state transitions are linear and monotonic, time acts as a first-class variable.

### 2.5 Invariants

1. **No Instant Exit**: withdrawals before cooldown are prohibited.
2. **Unique Stake Ownership**: a participant cannot bond multiple times without withdrawal.
3. **Capital Conservation**: total deposited tokens == total bonded + total withdrawable.
4. **Monotonic Exit Progression**: participants cannot skip or revert states.
5. **Cooldown Integrity**: withdrawals only after cooldown period.

### 2.6 Security Assumptions

- ERC-20 tokens used for bonding are compliant and secure.
- Blockchain timestamps are monotonic and within acceptable drift.
- Participants interact via the defined interface and cannot externally modify state.
- No external governance changes affect cooldown or bonding rules unexpectedly.

### 2.7 Threats / Adversarial Scenarios

- Early withdrawal attempts (bypassing cooldown)
- Double exit declarations
- Reentrancy on `withdraw()`
- Front-running exit transactions
- Multi-participant interference

### 2.8 Mitigations

- Require statements enforce correct state transitions.
- Checks-Effects-Interactions pattern prevents reentrancy.
- Per-participant state prevents cross-user interference.
- Tests simulate adversarial scenarios including time manipulation (`vm.warp`).

### 2.9 Residual Risks

- Cooldown set too short or too long can affect safety or UX (protocol-level tradeoff).
- Integration with external slashing or governance modules requires careful review.

---

## 3. Scope of the Protocol

### 3.1 What this protocol IS

`cooldown-staking` is a **staking exit control module** that:

- Accepts bonded capital (ERC-20 as a primitive)
- Enforces a _two-phase exit_:
  1. **Exit Intent Declaration**
  2. **Delayed Withdrawal after Cooldown**

- Models time as a _first-class system variable_
- Exposes explicit failure modes and penalties

It represents a **Security + Coordination layer module** in a broader protocol stack.

### 3.2 What this protocol is NOT

This project explicitly does **not**:

- Implement rewards, APY, or yield curves
- Optimize capital efficiency
- Include governance voting
- Include frontends, dashboards, or UX flows
- Act as a DeFi application

---

## 4. Protocol Layer Mapping

| Layer        | Role in this project                      |
| ------------ | ----------------------------------------- |
| Core / State | Stake ownership, balances, exit states    |
| Coordination | Cooldown periods, exit windows            |
| Security     | Exit delay, slashing window compatibility |
| Economics    | Capital bonding (no rewards)              |

---

## 5. Contract Responsibility Separation

- **StakingCore**: State machine rules
- **StakingStorage**: Balances, participant states
- **TimeCoordinator**: Cooldown logic

---

## 6. Protocol Interface

### Functions

1. `bond(uint256 amount)`
2. `declareExit()`
3. `withdraw()`
4. `getParticipantState(address participant) -> State`
5. `cooldownEnd(address participant) -> uint256`
6. `totalBonded() -> uint256`

### Events

1. `Bonded(address participant, uint256 amount)`
2. `ExitDeclared(address participant, uint256 timestamp)`
3. `Withdrawn(address participant, uint256 amount)`

---

## 7. Testing Philosophy & Invariant Tests

Tests are **protocol simulations**, not happy paths. Key testing strategies:

### 7.1 Invariant Tests

1. **No Instant Exit**: Attempt withdrawal immediately after `declareExit()` → expect revert
2. **Unique Stake Ownership**: Attempt multiple `bond()` calls from same participant without withdrawal → expect revert
3. **Capital Conservation**: Sum of all bonded + withdrawable tokens == total deposited tokens
4. **Monotonic Exit Progression**: Attempt to skip states or re-enter previous state → expect revert
5. **Cooldown Integrity**: Warp time to before cooldown ends and try withdrawal → expect revert
6. **Concurrent Participants**: Multiple participants declaring exit simultaneously should not interfere with each other’s state or balances

### 7.2 Adversarial Scenarios

- Attempt to withdraw from `UNBONDED` state → revert
- Attempt to declare exit twice → revert
- Attempt to manipulate time externally (`vm.warp`) → invariants hold
- Large-scale exit simulations → ensure total bonded capital never exceeds logical maximum

---

## 8. Threat Model (Formal)

### 8.1 Adversary Capabilities

- Participant can be malicious and try to bypass cooldown
- Participant can attempt multiple exit declarations
- Timestamp manipulation within blockchain bounds
- Reentrancy attempts on `withdraw()`
- Network congestion or front-running in exit windows

### 8.2 Security Assumptions

- ERC-20 token is secure and standard-compliant
- Blockchain timestamps are monotonic
- No external governance changes affecting cooldown unexpectedly

### 8.3 Attack Vectors & Mitigations

| Attack                         | Description                               | Mitigation                                                          |
| ------------------------------ | ----------------------------------------- | ------------------------------------------------------------------- |
| Instant Exit                   | Participant withdraws immediately         | require(exitTimestamp + cooldownPeriod <= now)                      |
| Double Exit Declaration        | Attempt to enter EXIT_PENDING twice       | state check, revert if already pending/ready                        |
| Reentrancy                     | Reentrant call on withdraw                | Checks-Effects-Interactions pattern, ReentrancyGuard optional       |
| Capital Loss                   | Withdrawn more than deposited             | invariant checks, sum(totalBonded + withdrawable) == totalDeposited |
| Multi-Participant Interference | Actions of one participant affect another | state per participant, no shared mutable state beyond global totals |

### 8.4 Residual Risks

- Cooldown too short → insufficient protection
- Cooldown too long → user dissatisfaction (protocol-level tradeoff)
- Integration with external slashing or governance modules requires careful compatibility checks

---

## 9. README Summary (Recruiter-Facing)

> This project implements a protocol-level cooldown staking module that enforces delayed exits for bonded capital.
>
> The design focuses on state transitions, time-based coordination, and economic safety rather than yield or application UX.
>
> It demonstrates protocol engineering skills including invariant design, adversarial thinking, and system-level testing.

---

## 10. Why This Project Matters

- Protocol-first thinking
- Explicit modeling of time and state
- Security-oriented design
- Separation of concerns
- Test-driven invariant validation
