# Participatory Budgeting System

This is a Ruby on Rails application designed to facilitate participatory budgeting, allowing community members to propose, discuss, and vote on budget allocations for various projects. It provides a transparent and democratic platform for collective decision-making.

## Key Features

- **Multi-Phase Budgeting:** Define and manage multiple phases for each budget (e.g., proposal submission, voting, implementation).
- **Category Spending Limits:** Set percentage-based spending caps for different budget categories to ensure balanced allocation.
- **Real-Time Voting Validation:** Prevents users from casting votes that would exceed a category's budget limit, with instant feedback.
- **Impact Assessment:** Project proposers can define impact metrics like estimated beneficiaries, sustainability score, and timeline.
- **Advanced Filtering & Sorting:** Users can filter and sort projects based on budget, category, status, and impact metrics.
- **Admin Dashboard:** A comprehensive backend for administrators to monitor system activity, manage limits, view analytics, and generate reports.
- **CSV Report Generation:** Admins can download detailed reports on projects, votes, users, and impact data.
- **Automatic Phase Transitions:** A Rake task automatically transitions budget phases based on their start and end dates.

## Setup and Installation

### Prerequisites

- Ruby (version specified in `.ruby-version`)
- Rails (version specified in `Gemfile`)
- PostgreSQL

### Steps

1.  **Clone the Repository**

    ```bash
    git clone <repository_url>
    cd participatory-budgeting-system
    ```

2.  **Install Dependencies**

    ```bash
    bundle install
    ```

3.  **Set Up the Database**
    Create and migrate the database. The seed command will populate the database with sample users, budgets, projects, and votes.

    ```bash
    rails db:create
    rails db:migrate
    rails db:seed
    ```

4.  **Run the Server**

    ```bash
    rails server
    ```

The application will be available at `http://localhost:3000`.

## Usage

Once the application is running, you can interact with it in two primary roles:

- **Participant:** Browse budgets, propose projects, and vote on them. You can sign up for a new account or use one of the pre-seeded participant accounts.
- **Administrator:** Access the admin dashboard to manage the system.

**Admin Login:**

- **Email:** `admin@participatorybudget.com`
- **Password:** `password123`

## Running Background Tasks

To ensure budget phases transition automatically, you can run the scheduled Rake task. In a production environment, this would typically be handled by a cron job or a scheduler add-on.

To run it manually:

```bash
rails budget:transition_phases
```
