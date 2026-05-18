import { MarketCreated } from "../../generated/MarketFactory/MarketFactory";
import { Market } from "../../generated/schema";

export function handleMarketCreated(event: MarketCreated): void {
  const id = event.params.marketId.toString();
  let market = new Market(id);
  market.marketId = event.params.marketId;
  market.market = event.params.market;
  market.amm = event.params.amm;
  market.yesId = event.params.yesId;
  market.noId = event.params.noId;
  market.state = "Trading";
  market.createdAt = event.block.timestamp;
  market.save();
}
