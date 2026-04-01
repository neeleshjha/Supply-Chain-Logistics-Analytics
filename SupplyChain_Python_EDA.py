"""
Supply Chain & Logistics Analytics — Full Python EDA Script
Project: Global Order Shipment & Supplier Performance | 2023
Libraries: pandas, numpy, matplotlib, seaborn
"""
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import seaborn as sns
import warnings
warnings.filterwarnings('ignore')

# ── Forest & Moss palette ──────────────────────────────────
P = ['#2C5F2D','#97BC62','#4A8C4F','#C8E6C9','#F4511E','#FF8A65','#1B5E20']
plt.rcParams.update({'font.family':'DejaVu Sans','axes.spines.top':False,
                     'axes.spines.right':False,'figure.facecolor':'white'})

df   = pd.read_csv('/home/claude/order_shipments.csv')
skpi = pd.read_csv('/home/claude/supplier_kpis.csv')
wkpi = pd.read_csv('/home/claude/warehouse_kpis.csv')
df['Order_Date']    = pd.to_datetime(df['Order_Date'])
df['Delivery_Date'] = pd.to_datetime(df['Delivery_Date'])
df['Month'] = df['Order_Date'].dt.to_period('M').astype(str)

print("="*60)
print("SUPPLY CHAIN & LOGISTICS — PYTHON EDA")
print("="*60)
print(f"\nOrders      : {len(df):,}  |  Suppliers: {df['Supplier'].nunique()}")
print(f"Date Range  : {df['Order_Date'].min().date()} → {df['Order_Date'].max().date()}")
print(f"Null values : {df.isnull().sum().sum()}")
print(f"\nNumeric Summary:")
print(df[['Actual_Lead_Days','Order_Value','Freight_Cost',
          'Defect_Rate_Pct','Supplier_Score']].describe().round(2).to_string())

# ════════════════════════════════════════════════════════════
# FIGURE 1 — Main EDA Dashboard
# ════════════════════════════════════════════════════════════
fig = plt.figure(figsize=(22,15))
fig.suptitle('Supply Chain & Logistics — EDA Dashboard',
             fontsize=18, fontweight='bold', color='#2C5F2D', y=0.98)
gs = gridspec.GridSpec(3,3,figure=fig,hspace=0.48,wspace=0.35)

# 1) Monthly order volume + total value trend
ax1 = fig.add_subplot(gs[0,:2])
mo = df.groupby('Month').agg(Orders=('Order_ID','count'),
                              Value=('Order_Value','sum')).reset_index()
ax1b = ax1.twinx()
ax1.bar(range(len(mo)), mo['Orders'], color='#2C5F2D', alpha=0.82, label='Order Count')
ax1b.plot(range(len(mo)), mo['Value']/1e6, color='#F4511E', marker='o',
          linewidth=2.5, markersize=5, label='Value ($M)')
ax1.set_xticks(range(len(mo)))
ax1.set_xticklabels([m[-5:] for m in mo['Month']], rotation=45, ha='right', fontsize=8)
ax1.set_title('Monthly Order Volume & Value', fontweight='bold', color='#2C5F2D')
ax1.set_ylabel('Order Count', color='#2C5F2D')
ax1b.set_ylabel('Value ($M)', color='#F4511E')
ax1.legend(loc='upper left'); ax1b.legend(loc='upper right')

# 2) Shipment mode mix
ax2 = fig.add_subplot(gs[0,2])
sm = df['Shipment_Mode'].value_counts()
ax2.pie(sm, labels=sm.index, autopct='%1.1f%%', colors=P[:len(sm)],
        startangle=90, pctdistance=0.80)
for t in ax2.texts: t.set_fontsize(8)
ax2.set_title('Shipment Mode Mix', fontweight='bold', color='#2C5F2D')

# 3) On-time delivery rate by carrier
ax3 = fig.add_subplot(gs[1,0])
otd = df.groupby('Carrier')['Is_Late'].apply(lambda x: (1-x.mean())*100).sort_values()
colors_otd = ['#F4511E' if v<50 else '#97BC62' if v<65 else '#2C5F2D' for v in otd.values]
ax3.barh(otd.index, otd.values, color=colors_otd)
ax3.axvline(otd.mean(), color='black', linestyle='--', linewidth=1.5,
            label=f'Avg: {otd.mean():.1f}%')
ax3.set_title('On-Time Delivery Rate by Carrier (%)', fontweight='bold', color='#2C5F2D')
ax3.set_xlabel('On-Time Rate (%)')
ax3.legend(fontsize=8)
for i,v in enumerate(otd.values): ax3.text(v+0.3,i,f'{v:.1f}%',va='center',fontsize=8)

# 4) Lead time distribution
ax4 = fig.add_subplot(gs[1,1])
ax4.hist(df['Actual_Lead_Days'], bins=25, color='#2C5F2D', edgecolor='white', alpha=0.85)
ax4.axvline(df['Actual_Lead_Days'].mean(), color='#F4511E', linestyle='--',
            linewidth=2, label=f"Mean: {df['Actual_Lead_Days'].mean():.1f}d")
ax4.axvline(df['Promised_Lead_Days'].mean(), color='#97BC62', linestyle='--',
            linewidth=2, label=f"Promised: {df['Promised_Lead_Days'].mean():.1f}d")
ax4.set_title('Actual vs Promised Lead Time Distribution', fontweight='bold', color='#2C5F2D')
ax4.set_xlabel('Days'); ax4.set_ylabel('Count')
ax4.legend(fontsize=8)

# 5) Supplier score vs defect rate
ax5 = fig.add_subplot(gs[1,2])
ax5.scatter(df['Supplier_Score'], df['Defect_Rate_Pct'],
            alpha=0.25, s=18, c='#2C5F2D')
corr = df[['Supplier_Score','Defect_Rate_Pct']].corr().iloc[0,1]
z = np.polyfit(df['Supplier_Score'], df['Defect_Rate_Pct'], 1)
xl = np.linspace(df['Supplier_Score'].min(), df['Supplier_Score'].max(), 100)
ax5.plot(xl, np.poly1d(z)(xl), 'r--', linewidth=2)
ax5.set_title(f'Supplier Score vs Defect Rate (r={corr:.2f})',
              fontweight='bold', color='#2C5F2D')
ax5.set_xlabel('Supplier Score'); ax5.set_ylabel('Defect Rate (%)')

# 6) Order value by category
ax6 = fig.add_subplot(gs[2,0])
cat_val = df.groupby('Product_Category')['Order_Value'].sum().sort_values(ascending=False)
ax6.bar(cat_val.index, cat_val.values/1e6, color='#2C5F2D', edgecolor='white', alpha=0.85)
ax6.set_title('Order Value by Product Category ($M)', fontweight='bold', color='#2C5F2D')
ax6.set_ylabel('Value ($M)'); ax6.tick_params(axis='x', rotation=35)
for i,v in enumerate(cat_val.values/1e6):
    ax6.text(i, v+0.2, f'${v:.0f}M', ha='center', fontsize=7.5, fontweight='bold')

# 7) Stockout rate by warehouse
ax7 = fig.add_subplot(gs[2,1])
so = wkpi.set_index('Warehouse')['Stockout_Rate'].sort_values(ascending=False)
colors_so = ['#F4511E' if v>30 else '#FF8A65' if v>20 else '#97BC62' for v in so.values]
ax7.bar(so.index, so.values, color=colors_so, edgecolor='white')
ax7.set_title('Stockout Rate by Warehouse (%)', fontweight='bold', color='#2C5F2D')
ax7.set_ylabel('Stockout Rate (%)')
ax7.tick_params(axis='x', rotation=30)
for i,v in enumerate(so.values): ax7.text(i, v+0.3, f'{v:.1f}%', ha='center', fontsize=9)

# 8) Cost breakdown by shipment mode
ax8 = fig.add_subplot(gs[2,2])
cost_mode = df.groupby('Shipment_Mode').agg(
    Order_Value =('Order_Value','sum'),
    Freight_Cost=('Freight_Cost','sum'),
    Holding_Cost=('Holding_Cost','sum')).div(1e6)
x = np.arange(len(cost_mode))
w = 0.28
ax8.bar(x-w,   cost_mode['Freight_Cost'],  w, color='#2C5F2D', label='Freight')
ax8.bar(x,     cost_mode['Holding_Cost'],  w, color='#97BC62',  label='Holding')
ax8.set_xticks(x); ax8.set_xticklabels(cost_mode.index)
ax8.set_title('Freight & Holding Cost by Mode ($M)', fontweight='bold', color='#2C5F2D')
ax8.set_ylabel('Cost ($M)'); ax8.legend(fontsize=8)

plt.savefig('/home/claude/scm_eda_dashboard.png', dpi=150, bbox_inches='tight')
print("\nMain EDA dashboard saved.")

# ════════════════════════════════════════════════════════════
# FIGURE 2 — Supplier & Risk Deep-Dive
# ════════════════════════════════════════════════════════════
fig2, axes = plt.subplots(1,3,figsize=(18,5))
fig2.suptitle('Supplier Performance & Risk Deep-Dive',
              fontsize=16, fontweight='bold', color='#2C5F2D')

# Supplier on-time rate vs score
axes[0].scatter(skpi['On_Time_Rate_Pct'], skpi['Avg_Score'],
                s=skpi['Total_Orders']*2, c='#2C5F2D', alpha=0.8, edgecolors='white', linewidth=0.8)
for _, row in skpi.iterrows():
    axes[0].annotate(row['Supplier'].split(' ')[0],
                     (row['On_Time_Rate_Pct'], row['Avg_Score']),
                     fontsize=8, ha='center', va='bottom', color='#1B5E20')
axes[0].set_title('On-Time Rate vs Supplier Score\n(Bubble = Order Volume)',
                  fontweight='bold')
axes[0].set_xlabel('On-Time Rate (%)'); axes[0].set_ylabel('Avg Supplier Score')
axes[0].axvline(skpi['On_Time_Rate_Pct'].mean(), color='#F4511E',
                linestyle='--', linewidth=1.5, alpha=0.7)
axes[0].axhline(skpi['Avg_Score'].mean(), color='#F4511E',
                linestyle='--', linewidth=1.5, alpha=0.7)

# Delay days distribution by priority
for pri, color in zip(['Critical','High','Medium','Low'],
                       ['#F4511E','#FF8A65','#97BC62','#C8E6C9']):
    sub = df[df['Priority']==pri]['Delay_Days']
    axes[1].hist(sub, bins=15, alpha=0.65, color=color, label=pri, edgecolor='white')
axes[1].set_title('Delay Days Distribution by Priority',fontweight='bold')
axes[1].set_xlabel('Delay Days'); axes[1].set_ylabel('Count')
axes[1].legend(fontsize=8)

# Defect rate heatmap: Supplier × Category
pivot = df.pivot_table(index='Supplier', columns='Product_Category',
                       values='Defect_Rate_Pct', aggfunc='mean')
sns.heatmap(pivot, annot=True, fmt='.1f', cmap='YlOrRd',
            ax=axes[2], linewidths=0.5, cbar_kws={'label':'Defect %'})
axes[2].set_title('Defect Rate % (Supplier × Category)', fontweight='bold')
axes[2].tick_params(axis='x', rotation=35)

for ax in axes: ax.spines['top'].set_visible(False); ax.spines['right'].set_visible(False)
plt.tight_layout()
plt.savefig('/home/claude/scm_supplier_analysis.png', dpi=150, bbox_inches='tight')
print("Supplier analysis saved.")

# ── Key Findings ──────────────────────────────────────────
print("\n── KEY FINDINGS ──────────────────────────────────────")
otd_overall = (1-df['Is_Late'].mean())*100
worst_carrier = otd.idxmin()
best_supplier = skpi.loc[skpi['On_Time_Rate_Pct'].idxmax(),'Supplier']
worst_supplier= skpi.loc[skpi['Avg_Defect_Pct'].idxmax(),'Supplier']
worst_wh_so   = wkpi.loc[wkpi['Stockout_Rate'].idxmax(),'Warehouse']
corr_val      = df[['Supplier_Score','Defect_Rate_Pct']].corr().iloc[0,1]
print(f"  Overall On-Time Rate  : {otd_overall:.1f}%")
print(f"  Worst Carrier (OTD)   : {worst_carrier} ({otd.min():.1f}%)")
print(f"  Best On-Time Supplier : {best_supplier}")
print(f"  Highest Defect Supplier: {worst_supplier} ({skpi['Avg_Defect_Pct'].max():.1f}%)")
print(f"  Highest Stockout WH   : {worst_wh_so} ({wkpi['Stockout_Rate'].max():.1f}%)")
print(f"  Corr(Score,Defect)    : {corr_val:.2f}")
print(f"  Avg Freight Cost      : ${df['Freight_Cost'].mean():,.0f}")
print(f"  Total Freight Spend   : ${df['Freight_Cost'].sum():,.0f}")
