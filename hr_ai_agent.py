# ================================================================
#  HR Analytics AI Agent — Jupyter Notebook
#  Project : AI Agent for Relational Database System
#  Stack   : MySQL + LangChain + Gemini (google-generativeai)
# ================================================================
#
#  HOW TO RUN:
#  1. pip install -r requirements below (Cell 1)
#  2. Fill in YOUR_PASSWORD and YOUR_GEMINI_KEY
#  3. Run cells top to bottom with Shift+Enter
#
# ================================================================


# ╔══════════════════════════════════════════════════════════════╗
# ║  CELL 1 — Install packages (run once, then skip next time)  ║
# ╚══════════════════════════════════════════════════════════════╝

# Uncomment and run this block once:
# !pip install langchain langchain-google-genai langchain-community
# !pip install mysql-connector-python sqlalchemy pymysql
# !pip install google-generativeai pandas matplotlib


# ╔══════════════════════════════════════════════════════════════╗
# ║  CELL 2 — Imports                                           ║
# ╚══════════════════════════════════════════════════════════════╝

import os
import warnings
warnings.filterwarnings("ignore")

import pandas as pd
import matplotlib
matplotlib.use("Agg")          # works inside Jupyter without GUI
import matplotlib.pyplot as plt

from sqlalchemy import create_engine, text
import mysql.connector

from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_community.utilities import SQLDatabase
from langchain_community.agent_toolkits import create_sql_agent
from langchain.agents.agent_types import AgentType

print("✅ All imports successful!")


# ╔══════════════════════════════════════════════════════════════╗
# ║  CELL 3 — Configuration  ⬅ EDIT THESE TWO VALUES           ║
# ╚══════════════════════════════════════════════════════════════╝

DB_CONFIG = {
    "host":     "localhost",
    "user":     "root",
    "password": "YOUR_MYSQL_PASSWORD",   # ← put your MySQL password here
    "database": "HR_Analytics",
}

GEMINI_API_KEY = "YOUR_GEMINI_API_KEY"  
# ↑ Get free key at: https://aistudio.google.com/app/apikey
#   Click "Create API key" → copy → paste here

print("✅ Config set!")


# ╔══════════════════════════════════════════════════════════════╗
# ║  CELL 4 — Test MySQL connection                             ║
# ╚══════════════════════════════════════════════════════════════╝

def test_mysql_connection():
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM emp_personal;")
        count = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM emp_tenure WHERE Attrition='Yes';")
        attrition = cursor.fetchone()[0]
        conn.close()
        print(f"✅ MySQL connected!")
        print(f"   Total employees  : {count}")
        print(f"   Employees who left: {attrition} ({attrition/count*100:.1f}%)")
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        print("   → Check your password and that MySQL is running")

test_mysql_connection()


# ╔══════════════════════════════════════════════════════════════╗
# ║  CELL 5 — Create SQLAlchemy engine + LangChain SQLDatabase  ║
# ╚══════════════════════════════════════════════════════════════╝

# SQLAlchemy connection string
connection_string = (
    f"mysql+mysqlconnector://{DB_CONFIG['user']}:{DB_CONFIG['password']}"
    f"@{DB_CONFIG['host']}/{DB_CONFIG['database']}"
)
engine = create_engine(connection_string)

# LangChain SQLDatabase — expose tables AND views so agent can query them
db = SQLDatabase(
    engine,
    include_tables=[
        "emp_personal",
        "emp_job_details",
        "emp_financial",
        "emp_feedback",
        "emp_tenure",
        "view_talent_retention",
        "view_overtime_satisfaction",
        "view_promotion_stagnation",
        "view_distance_attrition",
    ],
    sample_rows_in_table_info=3,   # shows agent 3 example rows per table
)

print("✅ SQLDatabase connected!")
print("   Available tables/views:", db.get_table_names())


# ╔══════════════════════════════════════════════════════════════╗
# ║  CELL 6 — Initialize Gemini LLM                            ║
# ╚══════════════════════════════════════════════════════════════╝

os.environ["GOOGLE_API_KEY"] = GEMINI_API_KEY

llm = ChatGoogleGenerativeAI(
    model="gemini-1.5-flash",      # fast + free tier friendly
    temperature=0,                  # deterministic SQL generation
    google_api_key=GEMINI_API_KEY,
)

# Quick sanity check
test_response = llm.invoke("Reply with only: OK")
print(f"✅ Gemini LLM initialized! Test response: {test_response.content}")


# ╔══════════════════════════════════════════════════════════════╗
# ║  CELL 7 — Build the SQL Agent                              ║
# ╚══════════════════════════════════════════════════════════════╝

agent = create_sql_agent(
    llm=llm,
    db=db,
    agent_type=AgentType.ZERO_SHOT_REACT_DESCRIPTION,
    verbose=True,           # shows agent's reasoning steps
    max_iterations=15,
    handle_parsing_errors=True,
    prefix="""You are an expert HR Data Analyst working with the HR_Analytics database.
The database contains 5 tables:
- emp_personal      : employee demographics (age, gender, marital status, distance from home)
- emp_job_details   : job info (department, role, overtime, job level, performance rating)
- emp_financial     : salary info (monthly income, salary hike, stock options)
- emp_feedback      : satisfaction scores (job, environment, work-life balance 1-4 scale)
- emp_tenure        : career history (years in company, promotion history, Attrition Yes/No)

There are 4 pre-built views for common analyses:
- view_talent_retention       : income vs attrition by department
- view_overtime_satisfaction  : satisfaction scores by overtime status and role
- view_promotion_stagnation   : employees with 5+ years without promotion
- view_distance_attrition     : attrition by commute distance, age group, marital status

Always write clear, actionable business insights in your final answer.
""",
)

print("✅ AI Agent is ready!")


# ╔══════════════════════════════════════════════════════════════╗
# ║  CELL 8 — INSIGHT 1: High-Value Talent Retention           ║
# ╚══════════════════════════════════════════════════════════════╝

print("\n" + "="*65)
print("INSIGHT 1: High-Value Talent Retention Analysis")
print("="*65)

result1 = agent.invoke("""
Analyze talent retention using view_talent_retention.

Answer these specific questions:
1. Which department has the highest attrition rate?
2. Are the employees who left (Attrition='Yes') earning more or less 
   than those who stayed? Compare AvgIncomeOfLeavers vs AvgIncomeOfStayers.
3. What is the financial cost risk for each department (combine 
   attrition rate × average income of leavers)?
4. Provide one concrete HR recommendation based on the data.
""")

print("\n🤖 AGENT ANSWER:")
print(result1["output"])


# ╔══════════════════════════════════════════════════════════════╗
# ║  CELL 9 — INSIGHT 2: Work-Life Balance & Overtime          ║
# ╚══════════════════════════════════════════════════════════════╝

print("\n" + "="*65)
print("INSIGHT 2: Work-Life Balance & Overtime Correlation")
print("="*65)

result2 = agent.invoke("""
Analyze the burnout effect of overtime using view_overtime_satisfaction.

Answer these specific questions:
1. Which job roles have the LOWEST average WorkLifeBalance 
   among overtime workers (OverTime = 'Yes')?
2. Compare the average JobSatisfaction for overtime vs non-overtime 
   across ALL job roles — is the difference significant?
3. Which role has the highest attrition rate among overtime workers?
4. Recommend which roles need immediate staffing policy changes.
""")

print("\n🤖 AGENT ANSWER:")
print(result2["output"])


# ╔══════════════════════════════════════════════════════════════╗
# ║  CELL 10 — INSIGHT 3: Promotion Stagnation                 ║
# ╚══════════════════════════════════════════════════════════════╝

print("\n" + "="*65)
print("INSIGHT 3: Promotion Stagnation & Performance Link")
print("="*65)

result3 = agent.invoke("""
Analyze promotion stagnation using view_promotion_stagnation.

Answer these specific questions:
1. What percentage of ALL employees have not been promoted in 5+ years?
   (Compare count in view vs total in emp_tenure)
2. Among stagnant employees, what is the average PerformanceRating 
   and JobInvolvement? Is it lower than the company average?
3. In which department is promotion stagnation most severe?
4. Are stagnant employees more likely to have Attrition='Yes'?
   Compare attrition rate of stagnant vs non-stagnant employees.
5. Suggest one specific promotion policy to fix this.
""")

print("\n🤖 AGENT ANSWER:")
print(result3["output"])


# ╔══════════════════════════════════════════════════════════════╗
# ║  CELL 11 — INSIGHT 4: Distance & Demographics              ║
# ╚══════════════════════════════════════════════════════════════╝

print("\n" + "="*65)
print("INSIGHT 4: Distance & Demographics Impact on Attrition")
print("="*65)

result4 = agent.invoke("""
Analyze commute distance impact using view_distance_attrition.

Answer these specific questions:
1. Among employees living MORE than 15 miles from work, which 
   MaritalStatus group has the highest attrition rate?
2. Which age group is most at risk from long commutes?
3. What is the overall attrition rate for far-commuters vs 
   the company average (use emp_tenure for company average)?
4. Should the company introduce remote work, relocation bonuses, 
   or both? For which specific demographic groups?
""")

print("\n🤖 AGENT ANSWER:")
print(result4["output"])


# ╔══════════════════════════════════════════════════════════════╗
# ║  CELL 12 — Direct SQL Queries with Pandas (visualization)  ║
# ╚══════════════════════════════════════════════════════════════╝

# ── Chart 1: Attrition Rate by Department ─────────────────────
df_retention = pd.read_sql("SELECT * FROM view_talent_retention", engine)
print("\n📊 VIEW 1 — Talent Retention:")
print(df_retention.to_string(index=False))

fig, axes = plt.subplots(1, 2, figsize=(12, 5))
axes[0].bar(df_retention["Department"], df_retention["AttritionRate_Pct"], 
            color=["#1a6b9a", "#2e8bc0", "#b1d4e0"])
axes[0].set_title("Attrition Rate by Department (%)")
axes[0].set_ylabel("Attrition Rate %")
axes[0].set_ylim(0, 30)

axes[1].bar(df_retention["Department"], df_retention["AvgMonthlyIncome"],
            color=["#1a6b9a", "#2e8bc0", "#b1d4e0"])
axes[1].set_title("Average Monthly Income by Department")
axes[1].set_ylabel("USD")

plt.tight_layout()
plt.savefig("chart1_retention.png", dpi=150)
plt.show()
print("   Saved: chart1_retention.png")


# ── Chart 2: WorkLifeBalance — Overtime vs Not ─────────────────
df_ot = pd.read_sql("""
    SELECT JobRole, OverTime, AvgWorkLifeBalance, AvgJobSatisfaction, AttritionRate_Pct
    FROM view_overtime_satisfaction
    ORDER BY JobRole, OverTime
""", engine)
print("\n📊 VIEW 2 — Overtime Satisfaction (first 10 rows):")
print(df_ot.head(10).to_string(index=False))

# ── Chart 3: Stagnation summary ────────────────────────────────
df_stag = pd.read_sql("""
    SELECT
        Department,
        COUNT(*)                                                AS StagnantEmployees,
        ROUND(AVG(YearsSinceLastPromotion), 1)                 AS AvgYearsWithoutPromotion,
        ROUND(AVG(PerformanceRating), 2)                        AS AvgPerformance,
        ROUND(AVG(JobInvolvement), 2)                           AS AvgInvolvement,
        SUM(CASE WHEN Attrition='Yes' THEN 1 ELSE 0 END)      AS Attrited
    FROM view_promotion_stagnation
    GROUP BY Department
""", engine)
print("\n📊 VIEW 3 — Stagnation by Department:")
print(df_stag.to_string(index=False))

# ── Chart 4: Distance Attrition ────────────────────────────────
df_dist = pd.read_sql("SELECT * FROM view_distance_attrition", engine)
print("\n📊 VIEW 4 — Distance Attrition:")
print(df_dist.to_string(index=False))

fig2, ax = plt.subplots(figsize=(10, 5))
pivot = df_dist.pivot_table(
    values="AttritionRate_Pct",
    index="MaritalStatus",
    columns="AgeGroup",
    aggfunc="mean"
)
im = ax.imshow(pivot.values, cmap="YlOrRd", aspect="auto")
ax.set_xticks(range(len(pivot.columns)))
ax.set_xticklabels(pivot.columns)
ax.set_yticks(range(len(pivot.index)))
ax.set_yticklabels(pivot.index)
ax.set_title("Attrition Rate % — Commuters (>15 miles)\nby Marital Status & Age Group")
plt.colorbar(im, ax=ax, label="Attrition %")
for r in range(len(pivot.index)):
    for c in range(len(pivot.columns)):
        val = pivot.values[r, c]
        if not pd.isna(val):
            ax.text(c, r, f"{val:.1f}", ha="center", va="center", fontsize=9)
plt.tight_layout()
plt.savefig("chart4_distance_heatmap.png", dpi=150)
plt.show()
print("   Saved: chart4_distance_heatmap.png")


# ╔══════════════════════════════════════════════════════════════╗
# ║  CELL 13 — Interactive Chat Mode (free-form questions)     ║
# ╚══════════════════════════════════════════════════════════════╝

print("\n" + "="*65)
print("🤖 INTERACTIVE HR ANALYTICS AGENT")
print("   Ask any question about the HR database in plain English.")
print("   Type 'quit' to exit.")
print("="*65)

while True:
    question = input("\n💬 Your question: ").strip()
    if question.lower() in ("quit", "exit", "q", ""):
        print("Session ended. Goodbye!")
        break
    try:
        response = agent.invoke(question)
        print(f"\n🤖 Agent: {response['output']}")
    except Exception as e:
        print(f"❌ Error: {e}")


# ╔══════════════════════════════════════════════════════════════╗
# ║  EXAMPLE QUESTIONS for the interactive agent:              ║
# ║                                                            ║
# ║  "What is the average salary of employees who quit?"       ║
# ║  "Which job role has the most overtime workers?"           ║
# ║  "Show me top 10 employees at risk of leaving"             ║
# ║  "How does education level affect income?"                 ║
# ║  "Compare satisfaction scores by marital status"           ║
# ║  "Which department has the most stagnant employees?"       ║
# ╚══════════════════════════════════════════════════════════════╝
