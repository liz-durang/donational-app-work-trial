# Donational

Donational encourages people to be deliberate about their charitable donations, and streamlines how funds are transferred to reduce complexity and fees.

In the same way that there are tools and “robo-advisors” to help people manage their retirement savings and their investment portfolios online, we are building a platform that helps donors to plan and to manage their impact on the world.

## How it works

Donational assists donors in two main areas:

### Select a portfolio of high impact charities

Instead of donating to whichever charity approaches you on the street or reaches you by phone, donors select charities that:

1. align with their values
2. make the greatest possible impact per each dollar donated

We give users access to information, research and recommendations from industry-experts that help guide a donor to select effective charities that will have positive impact on causes that are important to the them.

### Give what you ought to

Most charitable contributions are piecemeal, with amounts that fluctuate based on one's mood and that are unlikely to be tied to any sort of financial plan.

Donational asks people to reflect on how much an individual in our society ought to donate, and - with a single recurring payment - follow through to give what they believe they should.

By pooling pay outs to organizations, and avoiding credit card fees, we help ensure that giving with Donational is at-least as cost-efficient as other online donation methods.

# Developers

### Running the app (for the first time)

1. Run `bin/setup`
2. Populate `.env` with the relevant API Keys
3. Run `bin/start`

### Running tests

1. Run `bin/test`

## Code guidelines

1. *Do* follow bbatsov's [ruby style guide](https://github.com/bbatsov/ruby-style-guide) and [rails style guide](https://github.com/bbatsov/rails-style-guide)
2. *Do* use soft-delete on models (eg `Portfolio#deactivated_at`)
	- Since we deal with financial transactions, we need a clean audit trail
3. *Avoid* interacting directly with Models from a Controller (use a **Command** or **Query** object instead)
4. *Do* use **Command** objects whenever you want to mutate data (you can find them in `app/commands`)
	- We make use of the [`mutations gem`](https://github.com/cypriss/mutations) to help sanitize and validate input before executing the command
5. *Do* use **Query** objects for retrieving data (you can find them in `app/queries`)