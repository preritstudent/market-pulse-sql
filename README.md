# 📈 Market Pulse SQL

A stock market analytics project built from scratch using SQL Server and Python.
Pulls real-time data from Yahoo Finance and runs professional-grade SQL analysis.

---

## 🗄️ Database Structure

**companies** — stores company info (ticker, name, sector, country)  
**StockPrices** — stores 1 year of real daily OHLCV data for 5 stocks

---

## 📊 What This Project Covers

| Phase | Concept | What I Built |
|-------|---------|--------------|
| 1 | SELECT, WHERE, INSERT | Queried stock prices by ticker and date |
| 2 | GROUP BY, Aggregations | Found top performing stocks by avg price |
| 3 | INNER JOIN | Combined company info with real price data |
| 4 | Subqueries, CTEs | Found stocks beating their sector average |
| 5 | Window Functions | 30-day moving average, daily % return |
| 6 | Python ETL | Automated real data pipeline with yfinance |

---

## 🐍 Python ETL Pipeline

`fetch_stocks.py` pulls 1 year of real OHLCV data for:
**AAPL · TSLA · MSFT · GOOGL · AMZN**

```bash
# Setup
python3 -m venv venv
source venv/bin/activate
pip install yfinance pandas

# Run
python3 fetch_stocks.py
```

Outputs `stock_data.csv` with ~1,255 rows of real market data.

---

## 🛠️ Tools Used

- SQL Server 2022 via Docker
- Python 3.14 + yfinance + pandas
- VS Code with SQL Server extension
- Git + GitHub

---

## 📁 Files

| File | Description |
|------|-------------|
| `fetch_stocks.py` | Python script — pulls real stock data from Yahoo Finance |
| `queries.sql` | SQL analysis queries — joins, window functions, moving averages |
| `market_pulse_analysis.sql` | Original SQL queries from Phase 1–5 |

---

## 👤 Author

Prerit Gautam
