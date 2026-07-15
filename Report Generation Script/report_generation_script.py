import snowflake.connector
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import os
from dotenv import load_dotenv

load_dotenv()

ctx = snowflake.connector.connect(
    user=os.environ['SNOWFLAKE_USER'],
    password=os.environ['SNOWFLAKE_PASSWORD'],
    account=os.environ['SNOWFLAKE_ACCOUNT'],
    warehouse='COMPUTE_WH',
    database='WALMARTDB',
    schema='TRANSFORM'
)

query = """
SELECT
    f.store_id as store,
    f.dept_id,
    f.date_id,
    d.date,
    d.isholiday,
    s.store_type AS store_type,
    s.store_size,
    f.store_weekly_sales,
    f.temperature,
    f.fuel_price,
    f.cpi,
    f.unemployment,
    f.markdown1,
    f.markdown2,
    f.markdown3,
    f.markdown4,
    f.markdown5
FROM walmart_fact_table f
JOIN walmart_date_dim d
    ON f.date_id = d.date_id
JOIN walmart_store_dim s
    ON f.store_id = s.store_id
    AND f.dept_id = s.dept_id
"""

df = pd.read_sql(query, ctx)
ctx.close()

df.columns = df.columns.str.lower()
df['date'] = pd.to_datetime(df['date'])
df['year'] = df['date'].dt.year

df['month'] = df['date'].dt.strftime('%b')

month_order = [
    'Jan', 'Feb', 'Mar', 'Apr',
    'May', 'Jun', 'Jul', 'Aug',
    'Sep', 'Oct', 'Nov', 'Dec'
]

df['month'] = pd.Categorical(
    df['month'],
    categories=month_order,
    ordered=True
)

fig, axes = plt.subplots(2, 3, figsize=(45, 16))
fig.suptitle('Walmart — BI Analysis Report', fontsize=22, fontweight='bold')
fig.subplots_adjust(
    top=0.90,
    wspace=0.35,
    hspace=0.40
)

# 1. weekly sales by store and holiday
sales_store = (
    df
    .groupby(['store', 'isholiday'], as_index=False)
    .agg(weekly_sales=('store_weekly_sales', 'sum'))
    .sort_values(['store', 'isholiday'], ascending=[True, True])
)


def abbreviate(x):
    if abs(x) >= 1_000_000_000:
        return f'{x/1_000_000_000:.1f}B'
    elif abs(x) >= 1_000_000:
        return f'{x/1_000_000:.1f}M'
    elif abs(x) >= 1_000:
        return f'{x/1_000:.1f}K'
    else:
        return f'{x:.0f}'


def abbreviate_axis(x, pos):
    return abbreviate(x)


ax = sns.barplot(sales_store, x='store', y='weekly_sales',
                 hue='isholiday', ax=axes[0, 0])

for container in ax.containers:
    labels = [abbreviate(v) for v in container.datavalues]
    ax.bar_label(container, labels=labels, padding=3, fontsize=6)

ax.set_title('Weekly Sales by Store and Holiday')
ax.set_xlabel("Store")
ax.set_ylabel("Weekly Sales")
ax.yaxis.set_major_formatter(ticker.FuncFormatter(abbreviate_axis))
ax.tick_params(axis='x', rotation=45)
ax.legend(title='Holiday')

# 2. Weekly Sales by Temperature and Year

temp_sales = (
    df
    .groupby(['temperature', 'year'], as_index=False)
    .agg(weekly_sales=('store_weekly_sales', 'sum'))
    .sort_values(['temperature', 'year'], ascending=[True, True])
)

ax = sns.lineplot(temp_sales, x='temperature', y='weekly_sales',
                  hue='year', marker='o', ax=axes[0, 1])

ax.set_title('Weekly Sales by Temperature and Year')
ax.yaxis.set_major_formatter(ticker.FuncFormatter(abbreviate_axis))
ax.tick_params(axis='x', rotation=90)
ax.legend(title='Year')


# 3. Weekly sales by store size
sales_store_size = (
    df
    .groupby('store_size', as_index=False)
    .agg(weekly_sales=('store_weekly_sales', 'sum'))
    .sort_values('store_size', ascending=True)
)

ax = sns.scatterplot(sales_store_size, x='store_size',
                     y='weekly_sales', s=100, markers='o', ax=axes[0, 2])
ax.set_title('Weekly Sales by Store Size')
ax.yaxis.set_major_formatter(ticker.FuncFormatter(abbreviate_axis))

for i, row in sales_store_size.iterrows():
    offset = 15 if i % 2 == 0 else -20

    ax.annotate(
        abbreviate(row['weekly_sales']),
        (row['store_size'], row['weekly_sales']),
        xytext=(0, offset),
        textcoords='offset points',
        ha='center',
        fontsize=8
    )


# 4. Weekly sales by store type and month.
type_sales = (
    df.pivot_table(
        index='month',
        columns='store_type',
        values='store_weekly_sales',
        aggfunc='sum'
    )
    .sort_index()
    .reset_index()
)


type_sales = (
    type_sales
    .reset_index()
    .melt(
        id_vars='month',
        var_name='store_type',
        value_name='weekly_sales'
    )
)

ax = sns.lineplot(type_sales, x='month',
                  y='weekly_sales', hue='store_type', marker='o', ax=axes[1, 0])

for store_type, group in type_sales.groupby('store_type'):
    for _, row in group.iterrows():
        ax.annotate(
            abbreviate(row['weekly_sales']),
            (row['month'], row['weekly_sales']),
            xytext=(0, 8),
            textcoords='offset points',
            ha='center',
            fontsize=6
        )

ax.set_title('Weekly Sales by Store type and Month')
ax.yaxis.set_major_formatter(ticker.FuncFormatter(abbreviate_axis))
ax.legend(title='Store Type')

# 5. Weekly sales by store type.

wide = (
    df
    .pivot_table(values='store_weekly_sales', columns='store_type', aggfunc='sum')
    # drop the meaningless index, since there's only 1 row
    .reset_index(drop=True)
)

long_from_wide = wide.melt(var_name='store_type', value_name='weekly_sales')

long_from_wide = long_from_wide.sort_values('weekly_sales', ascending=True)

ax = sns.barplot(
    data=long_from_wide,
    x='weekly_sales',
    y='store_type',
    orient='h',
    ax=axes[1, 1]
)

ax.set_title('Total Weekly Sales by Store Type')
ax.xaxis.set_major_formatter(ticker.FuncFormatter(abbreviate_axis))

for container in ax.containers:
    labels = [abbreviate(v) for v in container.datavalues]
    ax.bar_label(container, labels=labels, padding=3, fontsize=10)

# 6. Fuel price by year.

fuel_sales = (
    df
    .groupby(['store', 'year'], as_index=False)
    .agg(total_fuel_price=('fuel_price', 'sum'))
    .sort_values(['store', 'year'], ascending=[True, True])
)

ax = sns.lineplot(fuel_sales, x='total_fuel_price',
                  y='store', hue='year', marker='o', ax=axes[1, 2])

ax.set_title('Total Fuel price by year')
ax.xaxis.set_major_formatter(ticker.FuncFormatter(abbreviate_axis))

for _, row in fuel_sales.iterrows():
    ax.annotate(
        abbreviate(row['total_fuel_price']),
        (row['total_fuel_price'], row['store']),
        xytext=(8, 0),
        textcoords='offset points',
        fontsize=5
    )

plt.tight_layout(rect=[0, 0, 1, 0.96])
plt.savefig('walmart_bi_analysis_report.pdf', dpi=200, bbox_inches='tight')
plt.show()
