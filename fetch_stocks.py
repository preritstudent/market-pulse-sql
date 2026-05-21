import yfinance as yf
import pandas as pd

tickers = ["AAPL", "TSLA", "MSFT", "GOOGL", "AMZN"]
all_data = []

for ticker in tickers:
    print(f"Fetching data for {ticker}...")
    stock = yf.Ticker(ticker)
    df = stock.history(period="1y")
    df["Ticker"] = ticker
    df = df.reset_index()
    df = df[["Ticker","Date","Open","High","Low","Close","Volume"]]
    all_data.append(df)
    print(f"  Got {len(df)} rows")

combined = pd.concat(all_data, ignore_index=True)
combined["Open"]  = combined["Open"].round(2)
combined["High"]  = combined["High"].round(2)
combined["Low"]   = combined["Low"].round(2)
combined["Close"] = combined["Close"].round(2)
combined["Date"]  = combined["Date"].dt.strftime("%Y-%m-%d")

combined.to_csv("stock_data.csv", index=False)
print(f"\nDone! Saved {len(combined)} rows to stock_data.csv")
print(combined.head(10).to_string(index=False))