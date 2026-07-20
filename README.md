# Acquisition-Led Growth Strategy Analysis: Suprajit Engineering (FY21–FY25)

**Revenue nearly doubled while profit after tax fell 30%. Only one of those was the core business.**

A strategic and financial analysis of whether Suprajit Engineering's acquisition-led international expansion strengthened the underlying business, or only bought scale.

**Verdict: Strategically successful, financially incomplete.**

`Power BI` · `DAX` · `SQL` · `Excel`

---

## The business question

Between FY21 and FY25, Suprajit doubled revenue (+99.7%) while profit after tax fell 30.4%. A company got twice as big and earned a third less.

The question this project answers is the one any board, investor, or acquirer would ask:

> **Did management sacrifice profitability to build a stronger company, and was that trade-off justified?**

---

## The dashboard

![Suprajit Dashboard](assets/dashboard-full.jpg)

Two interactive elements do the analytical work. A consolidated / ex-acquisition toggle flips the profit story between the reported collapse and the underlying business in one click. A counterfactual slider lets the reader test how fast the international regions would have had to grow without the acquisition to reach the same diversification. They would have had to grow implausibly fast, which is the point.

![The toggle in action](assets/dashboard-toggle.gif)

---

## Data

The data comes from Suprajit's own annual reports (FY21 to FY25) and the Q4 FY25 results release. These are primary disclosures, extracted by hand. The set covers five fiscal years of consolidated financials, geographic revenue splits, cost structure, and segment-level figures.

It is a small, primary-source dataset rather than a large machine-readable one. The work is in the reasoning applied to it, not the volume. Every figure was pulled from a source document and reconciled before it was used.

---

## Approach

I standardised five years of annual-report financials in Excel into consistent, analysis-ready tables.

I then validated every figure in SQL, using CTEs and window functions behind a reconciliation gate. Geographic revenue was checked back against reported consolidated totals, and each finding traces to a specific query.

I also checked what management said against what the numbers showed, testing each stated strategic objective against the reported financials and marking it validated, partially validated, or still in progress.

The findings are presented two ways. The first is a 30-page written analysis that builds the argument chapter by chapter, from evidence to verdict. The second is an interactive Power BI dashboard built on a star-schema model, where a shared date dimension filters multiple fact tables. It uses DAX measures, a what-if parameter, and revenue and profit rebased to a common index (FY21 = 100) so two series of very different scale can be read on one honest axis.

---

## The finding that changes the story

On the surface, the expansion looked like value destruction. Revenue doubled, profit fell 30%.

It wasn't. The FY25 profit collapse traced almost entirely to a single distressed acquisition, Stahlschmidt Cable Systems (SCS), bought out of German insolvency proceedings and still mid-restructuring, plus the one-off charges that came with it.

Strip SCS out, and the underlying business grew EBITDA 23.1% (₹3,259M to ₹4,011M), with margin rising from 11.3% to 12.9%.

The reported numbers told a story of decline. The underlying numbers told a story of a healthy business absorbing the temporary cost of a turnaround acquisition. That gap is the whole analysis.

---

## Supporting findings

The business became majority-international for the first time. Revenue mix shifted from 39.7% to 51.8% international, with India growing 59.6% over the period, the USA 133.6%, and the Rest of World 192.0%.

Margins compressed 426 bps, but the factory got leaner while the organisation got heavier. Material cost as a share of revenue actually improved by 139 bps. The pressure came from employee costs (up 343 bps) and overhead (up 221 bps), which is the price of building and integrating a global operation, not a sign of manufacturing inefficiency.

Operating EBITDA still grew 40.8% even as PAT fell. That split between operating performance and bottom-line profit is the core paradox the project resolves.

---

## Judgment calls

*The reasoning behind the methodology, including the things I chose not to do.*

**Why India is the counterfactual control.** To estimate what the expansion actually caused, I needed a baseline for what would have happened anyway. India is the part of the business that did not receive the acquisition, so its organic growth of 59.6% over the period is the closest available control. When I model the international regions at that same rate, the business stays below 50% international under every plausible scenario. Reaching the actual majority-international mix would have needed international growth of about 142%, roughly 2.4 times India's rate, which is not a realistic organic outcome. That is the evidence that the diversification was caused by the acquisition rather than being coincidental to it.

**Why I rebased both series to an index.** Revenue and profit differ in scale by about 20 times. Put them on a shared axis and profit flattens into a nearly straight line. Put them on dual axes and you get a dramatic-looking crossing point that means nothing. Rebasing both to 100 at FY21 removes both problems. You see revenue climb to about 200 and profit fall to about 70 on one honest scale, and the gap between them is real rather than an artefact of scaling.

**Why I only estimated what the data could support.** The counterfactual could answer some questions honestly and not others. How much revenue the expansion added is estimable, with medium confidence. How much it changed diversification is estimable, with high confidence. But what profit margins would have been without the acquisition depends on assumptions the disclosures simply do not contain. So instead of inventing a number to fill the gap, I marked it "not estimated" and tagged a confidence level on every conclusion. Being clear about what you cannot prove is part of the analysis, not a hole in it.

```text

suprajit-acquisition-analysis/
├── README.md
├── report/
│   └── SUPRAJIT_ANALYSIS.pdf          full written analysis
├── sql/
│   └── suprajit_analysis.sql          validation gate and analytical queries
├── dashboard/
│   └── suprajit-dashboard.pbix        interactive Power BI file
└── assets/
    ├── dashboard-full.jpg             full dashboard view
    └── dashboard-toggle.gif           the ex-SCS toggle in action
```


## The verdict, in full

Suprajit's expansion succeeded strategically and remains incomplete financially. The company is now larger, majority-international, and more diversified than it was in FY21, and organic growth could not plausibly have produced those gains. The financial payoff, meaning margin recovery and shareholder returns, has only started to show by FY25.

One thing would change this conclusion. If SCS fails to recover, or FY26 margins do not improve, the reading of these costs as temporary gets weaker. The verdict is a judgment on the evidence available through FY25, held with appropriate confidence. It is not a certainty.
