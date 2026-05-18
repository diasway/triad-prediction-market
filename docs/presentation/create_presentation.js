const pptxgen = require("pptxgenjs");
const {
  warnIfSlideHasOverlaps,
  warnIfSlideElementsOutOfBounds,
} = require("/home/oai/skills/slides/pptxgenjs_helpers");
const pptx = new pptxgen();
pptx.layout = "LAYOUT_WIDE";
pptx.author = "Mukhametkali Dias, Qaldyqan Yerzat, Rudov Andrew";
pptx.subject = "TriadMarket Final Project";
pptx.title = "TriadMarket Final Presentation";
pptx.company = "Blockchain Technologies 2";
pptx.lang = "en-US";
pptx.theme = {
  headFontFace: "Aptos Display",
  bodyFontFace: "Aptos",
  lang: "en-US",
};
const W = 13.333,
  H = 7.5;
const navy = "0B1220",
  blue = "2563EB",
  cyan = "06B6D4",
  text = "E5E7EB",
  muted = "94A3B8",
  white = "FFFFFF";
function bg(slide) {
  slide.background = { color: navy };
}
function title(slide, t, sub) {
  slide.addText(t, {
    x: 0.55,
    y: 0.35,
    w: 7.8,
    h: 0.48,
    fontSize: 25,
    bold: true,
    color: white,
    margin: 0,
  });
  if (sub)
    slide.addText(sub, {
      x: 0.58,
      y: 0.9,
      w: 9,
      h: 0.3,
      fontSize: 10.5,
      color: muted,
      margin: 0,
    });
}
function foot(slide, n) {
  slide.addText(`TriadMarket | ${n}`, {
    x: 10.9,
    y: 7.05,
    w: 1.7,
    h: 0.18,
    fontSize: 7.5,
    color: muted,
    align: "right",
    margin: 0,
  });
}
function bullets(slide, arr, x, y, w, h, fs = 15) {
  slide.addText(arr.map((s) => "• " + s).join("\n"), {
    x,
    y,
    w,
    h,
    fontSize: fs,
    color: text,
    breakLine: false,
    fit: "shrink",
    valign: "mid",
    margin: 0.05,
    paraSpaceAfterPt: 7,
  });
}
function tag(slide, t, x, y) {
  slide.addText(t, {
    x,
    y,
    w: 2.15,
    h: 0.24,
    fontSize: 9,
    bold: true,
    color: cyan,
    margin: 0,
  });
}
function check(slide, n) {
  warnIfSlideHasOverlaps(slide, pptx, { ignoredIds: [] });
  warnIfSlideElementsOutOfBounds(slide, pptx);
  foot(slide, n);
}

let s = pptx.addSlide();
bg(s);
s.addText("TriadMarket", {
  x: 0.7,
  y: 2.15,
  w: 6.1,
  h: 0.65,
  fontSize: 44,
  bold: true,
  color: white,
  margin: 0,
});
s.addText("DAO-governed on-chain prediction market", {
  x: 0.74,
  y: 2.95,
  w: 7.0,
  h: 0.34,
  fontSize: 18,
  color: muted,
  margin: 0,
});
s.addText("Mukhametkali Dias  |  Qaldyqan Yerzat  |  Rudov Andrew", {
  x: 0.75,
  y: 4.05,
  w: 8.7,
  h: 0.28,
  fontSize: 12,
  color: text,
  margin: 0,
});
s.addText("Blockchain Technologies 2 — Final Project", {
  x: 0.75,
  y: 4.42,
  w: 5.2,
  h: 0.25,
  fontSize: 10.5,
  color: muted,
  margin: 0,
});
check(s, 1);

s = pptx.addSlide();
bg(s);
title(
  s,
  "Scenario and product idea",
  "Option D: binary outcome market with AMM pricing and oracle resolution",
);
bullets(
  s,
  [
    "Users trade YES/NO outcome shares for a future event.",
    "Outcome shares are ERC-1155 tokens created per market.",
    "Trading uses our own constant-product AMM with 0.3% fee.",
    "Resolution uses a Chainlink price feed through a staleness-checked adapter.",
  ],
  0.75,
  1.65,
  6.0,
  3.0,
  17,
);
tag(s, "Core thesis", 8.0, 1.6);
s.addText(
  "The project is not only smart contracts. It is a full protocol package: contracts, tests, audit, frontend, subgraph, CI, deployment scripts, and presentation.",
  {
    x: 8.0,
    y: 2.0,
    w: 4.2,
    h: 1.55,
    fontSize: 16,
    bold: true,
    color: white,
    fit: "shrink",
    margin: 0.05,
  },
);
check(s, 2);

s = pptx.addSlide();
bg(s);
title(
  s,
  "Requirement coverage",
  "Mapping the rubric to concrete implementation",
);
bullets(
  s,
  [
    "UUPS upgrade: UpgradeableTreasury V1 -> V2.",
    "CREATE + CREATE2: MarketFactory deploys deterministic markets and AMMs.",
    "Token standards: ERC20Votes/Permit, ERC-1155, ERC-4626.",
    "DeFi primitive: scratch-built CPMM with LP tokens.",
    "Oracle + governance + L2 deployment scripts included.",
  ],
  0.75,
  1.5,
  11.5,
  4.4,
  15.5,
);
check(s, 3);

s = pptx.addSlide();
bg(s);
title(
  s,
  "Architecture overview",
  "The protocol is split into clear security domains",
);
tag(s, "Tokens", 0.8, 1.45);
bullets(
  s,
  [
    "TRIAD governance token",
    "OutcomeToken ERC-1155",
    "LP token",
    "ERC-4626 fee vault",
  ],
  0.8,
  1.85,
  3.2,
  2.1,
  13.5,
);
tag(s, "Protocol", 4.9, 1.45);
bullets(
  s,
  ["MarketFactory", "PredictionMarket", "OutcomeAMM", "ChainlinkPriceOracle"],
  4.9,
  1.85,
  3.2,
  2.1,
  13.5,
);
tag(s, "Governance", 8.9, 1.45);
bullets(
  s,
  ["Governor", "TimelockController", "Proposal lifecycle", "Treasury control"],
  8.9,
  1.85,
  3.2,
  2.1,
  13.5,
);
s.addText(
  "Critical authority moves to Timelock after deployment, so individual deployer/admin power is reduced.",
  {
    x: 1.0,
    y: 5.25,
    w: 11.2,
    h: 0.55,
    fontSize: 18,
    bold: true,
    color: white,
    align: "center",
    margin: 0,
  },
);
check(s, 4);

s = pptx.addSlide();
bg(s);
title(s, "Trading flow", "How a trader uses the market");
bullets(
  s,
  [
    "Trader deposits collateral into PredictionMarket.",
    "Market mints equal YES and NO ERC-1155 outcome shares.",
    "Trader swaps one outcome for the other in OutcomeAMM.",
    "AMM enforces x*y=k and min-output slippage protection.",
    "After resolution, winning shares redeem collateral.",
  ],
  0.8,
  1.55,
  5.9,
  4.4,
  16,
);
s.addText(
  "Main invariant: after a swap, the reserve product should not decrease except for precisely accounted rounding and fee logic.",
  {
    x: 7.4,
    y: 2.0,
    w: 4.8,
    h: 1.2,
    fontSize: 18,
    bold: true,
    color: white,
    fit: "shrink",
    margin: 0.05,
  },
);
check(s, 5);

s = pptx.addSlide();
bg(s);
title(s, "Governance flow", "Full OpenZeppelin Governor stack");
bullets(
  s,
  [
    "TRIAD holders delegate voting power before proposing/voting.",
    "Voting delay: 1 day; voting period: 1 week.",
    "Quorum: 4%; proposal threshold: 1%.",
    "Timelock delay: 2 days before execution.",
    "Post-deployment script checks that no admin backdoor remains.",
  ],
  0.75,
  1.5,
  11.0,
  4.0,
  16,
);
check(s, 6);

s = pptx.addSlide();
bg(s);
title(s, "Security model", "Defenses required by the rubric");
bullets(
  s,
  [
    "CEI and ReentrancyGuard are used on external state-changing flows.",
    "All ERC-20 transfers use SafeERC20.",
    "Privileged functions use Ownable or AccessControl.",
    "No tx.origin authorization; no transfer/send ETH pattern.",
    "Case studies reproduce and fix reentrancy and access-control vulnerabilities.",
  ],
  0.8,
  1.5,
  11.5,
  4.4,
  15.5,
);
check(s, 7);

s = pptx.addSlide();
bg(s);
title(
  s,
  "Oracle and resolution",
  "Chainlink adapter protects market resolution",
);
bullets(
  s,
  [
    "Adapter checks answer > 0.",
    "Adapter checks answeredInRound >= roundId.",
    "Adapter rejects stale prices older than maxAge.",
    "Market resolves YES if price >= threshold after dispute window.",
    "This keeps oracle validation in one auditable place.",
  ],
  0.8,
  1.55,
  11.2,
  4.1,
  16,
);
check(s, 8);

s = pptx.addSlide();
bg(s);
title(s, "Frontend and subgraph", "Full-stack protocol demonstration");
bullets(
  s,
  [
    "Wallet connection through MetaMask and WalletConnect.",
    "Reads TRIAD balance, voting power, delegate address, and market state.",
    "Supports state-changing actions: delegate, vote, deposit/swap flow.",
    "Subgraph indexes Market, Trade, LiquidityPosition, VaultDeposit, ProposalSnapshot.",
    "UI handles wrong network, rejected transactions, and insufficient balances.",
  ],
  0.75,
  1.5,
  11.5,
  4.4,
  15.5,
);
check(s, 9);

s = pptx.addSlide();
bg(s);
title(s, "Testing and CI", "How the project is defended technically");
bullets(
  s,
  [
    "Unit tests target every public/external function and revert path.",
    "Fuzz tests cover swaps, vault actions, and voting power.",
    "Invariant tests cover AMM k, supply conservation, and treasury accounting.",
    "Fork tests are prepared for USDC, Uniswap router, and Chainlink feed checks.",
    "GitHub Actions runs build, tests, coverage, Slither, linting, and frontend build.",
  ],
  0.75,
  1.45,
  11.7,
  4.7,
  15.5,
);
check(s, 10);

s = pptx.addSlide();
bg(s);
title(
  s,
  "Team contribution",
  "Each member owns a domain but must understand the whole system",
);
bullets(
  s,
  [
    "Dias: AMM, outcome token, vault, gas report.",
    "Qaldyqan: governance, oracle, upgradeability, audit report.",
    "Andrew: frontend, subgraph, CI/CD, deployment documentation.",
    "During Q&A, every member can explain the architecture and critical security assumptions.",
  ],
  0.8,
  1.55,
  11.5,
  4.1,
  16,
);
check(s, 11);

s = pptx.addSlide();
bg(s);
title(s, "Final defense message", "What we want the instructor to remember");
s.addText(
  "TriadMarket demonstrates the required Blockchain Technologies 2 domains in one coherent protocol: tokens, DeFi AMM, oracle safety, governance, upgradeability, indexing, frontend, DevOps, and security review.",
  {
    x: 1.0,
    y: 2.2,
    w: 11.1,
    h: 1.55,
    fontSize: 24,
    bold: true,
    color: white,
    align: "center",
    fit: "shrink",
    margin: 0.05,
  },
);
s.addText(
  "The strongest defense angle: every major design choice is documented, tested, and connected to a rubric requirement.",
  {
    x: 1.4,
    y: 4.45,
    w: 10.3,
    h: 0.45,
    fontSize: 16,
    color: muted,
    align: "center",
    margin: 0,
  },
);
check(s, 12);

pptx.writeFile({
  fileName:
    "/mnt/data/triad-prediction-market/docs/presentation/TriadMarket_Final_Presentation.pptx",
});
