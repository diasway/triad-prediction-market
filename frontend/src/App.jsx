import React, { useEffect, useMemo, useState } from 'react';
import { createConfig, http, WagmiProvider, useAccount, useReadContract, useWriteContract, useSwitchChain } from 'wagmi';
import { arbitrumSepolia } from 'wagmi/chains';
import { injected, walletConnect } from 'wagmi/connectors';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { GraphQLClient, gql } from 'graphql-request';
import { parseUnits, formatUnits } from 'viem';

const projectId = 'demo-walletconnect-project-id-replace-me';
const config = createConfig({
  chains: [arbitrumSepolia],
  connectors: [injected(), walletConnect({ projectId })],
  transports: { [arbitrumSepolia.id]: http() },
});
const queryClient = new QueryClient();

const erc20VotesAbi = [
  { name: 'balanceOf', type: 'function', stateMutability: 'view', inputs: [{ name: 'a', type: 'address' }], outputs: [{ type: 'uint256' }] },
  { name: 'getVotes', type: 'function', stateMutability: 'view', inputs: [{ name: 'a', type: 'address' }], outputs: [{ type: 'uint256' }] },
  { name: 'delegates', type: 'function', stateMutability: 'view', inputs: [{ name: 'a', type: 'address' }], outputs: [{ type: 'address' }] },
  { name: 'delegate', type: 'function', stateMutability: 'nonpayable', inputs: [{ name: 'delegatee', type: 'address' }], outputs: [] },
];
const governorAbi = [
  { name: 'state', type: 'function', stateMutability: 'view', inputs: [{ name: 'proposalId', type: 'uint256' }], outputs: [{ type: 'uint8' }] },
  { name: 'castVote', type: 'function', stateMutability: 'nonpayable', inputs: [{ name: 'proposalId', type: 'uint256' }, { name: 'support', type: 'uint8' }], outputs: [{ type: 'uint256' }] },
];
const marketAbi = [
  { name: 'buyCompleteSet', type: 'function', stateMutability: 'nonpayable', inputs: [{ name: 'amount', type: 'uint256' }], outputs: [] },
];

function stateName(s) {
  return ['Pending', 'Active', 'Canceled', 'Defeated', 'Succeeded', 'Queued', 'Expired', 'Executed'][Number(s)] ?? 'Unknown';
}

function Dashboard() {
  const { address, chain } = useAccount();
  const { switchChain } = useSwitchChain();
  const { writeContractAsync } = useWriteContract();
  const [error, setError] = useState('');
  const [markets, setMarkets] = useState([]);
  const triad = import.meta.env.VITE_TRIAD;
  const governor = import.meta.env.VITE_GOVERNOR;
  const targetChain = Number(import.meta.env.VITE_CHAIN_ID || 421614);

  const balance = useReadContract({ abi: erc20VotesAbi, address: triad, functionName: 'balanceOf', args: [address], query: { enabled: Boolean(address) } });
  const votes = useReadContract({ abi: erc20VotesAbi, address: triad, functionName: 'getVotes', args: [address], query: { enabled: Boolean(address) } });
  const delegate = useReadContract({ abi: erc20VotesAbi, address: triad, functionName: 'delegates', args: [address], query: { enabled: Boolean(address) } });

  async function safeTx(fn) {
    setError('');
    try { await fn(); }
    catch (e) {
      const msg = e?.shortMessage || e?.message || 'Transaction failed';
      if (msg.toLowerCase().includes('user rejected')) setError('Transaction rejected in wallet.');
      else if (msg.toLowerCase().includes('insufficient')) setError('Insufficient balance or allowance.');
      else setError(msg.slice(0, 180));
    }
  }

  useEffect(() => {
    const url = import.meta.env.VITE_SUBGRAPH_URL;
    if (!url) return;
    const client = new GraphQLClient(url);
    client.request(gql`{ markets(first: 10, orderBy: createdAt, orderDirection: desc) { id marketId market amm yesId noId state } }`)
      .then((r) => setMarkets(r.markets || []))
      .catch(() => setError('Could not load subgraph data. Check subgraph URL.'));
  }, []);

  if (!address) return <main><h1>TriadMarket</h1><p>Connect MetaMask or WalletConnect to continue.</p></main>;
  if (chain?.id !== targetChain) return <main><h1>Wrong network</h1><button onClick={() => switchChain({ chainId: targetChain })}>Switch to Arbitrum Sepolia</button></main>;

  return <main>
    <h1>TriadMarket Dashboard</h1>
    {error && <p className="error">{error}</p>}
    <section><h2>Governance</h2>
      <p>TRIAD balance: {balance.data ? formatUnits(balance.data, 18) : '0'}</p>
      <p>Voting power: {votes.data ? formatUnits(votes.data, 18) : '0'}</p>
      <p>Delegate: {delegate.data || 'not delegated'}</p>
      <button onClick={() => safeTx(() => writeContractAsync({ address: triad, abi: erc20VotesAbi, functionName: 'delegate', args: [address] }))}>Delegate to self</button>
    </section>
    <section><h2>Markets from The Graph</h2>{markets.map(m => <article key={m.id}><b>Market #{m.marketId}</b><p>AMM: {m.amm}</p><p>State: {m.state}</p></article>)}</section>
    <section><h2>Protocol actions</h2>
      <button onClick={() => safeTx(() => writeContractAsync({ address: governor, abi: governorAbi, functionName: 'castVote', args: [1n, 1] }))}>Vote For Proposal #1</button>
      <button onClick={() => alert('Deposit uses the selected market address from subgraph in production build.')}>Deposit collateral</button>
      <button onClick={() => alert('Swap uses selected AMM address from subgraph in production build.')}>Swap outcome shares</button>
    </section>
  </main>;
}

export default function App() {
  return <WagmiProvider config={config}><QueryClientProvider client={queryClient}><Dashboard /></QueryClientProvider></WagmiProvider>;
}
