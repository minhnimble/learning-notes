# Managing Products with Agility

## Forecasting and Release Planning

### Myth: Story Points are Required in Scrum

Several methods exist to estimate Story Points, including [Planning Poker](https://en.wikipedia.org/wiki/Planning_poker) and [Magic Estimation](https://www.scrum.nl/blog/magic-estimation/).

#### The Purpose of Estimation in Scrum

- In plan-based approaches, estimates are used to arrive at budgets and to determine delivery dates.
- Estimations give DTs a rough sense of the amount of work they can pull into a Sprint.
- In complex environments, what will happen in the (near) future is largely unknown → use the empirical process of Scrum to capitalize on change rather than control against it.

4 important insights regarding estimates:
- Accurate estimates are impossible.
- An estimate can't be a guarantee.
- The time we spend on estimation is a form of waste.
- The estimates are the result of a necessary conversation within the DT to arrive at a shared understanding.

Disadvantages of time-based estimates (hours, days):
- Time-based estimates uphold the illusion of accuracy and predictability.
- Illusion of accuracy often drives teams into ‘analysis paralysis’, where all details need to be discussed in-depth in order to arrive at a detailed estimate.

→ Story Points are a lightweight approach to get a rough idea of how much work can be completed in a Sprint.

#### Why Estimate At All?

Some alternatives to estimating individual items:
- Use the number of items per Sprint as a guide to select a doable amount of work for a Sprint.
- Use size buckets as a guide, where the Development Team classifies items in terms of size (e.g. large, medium, small). 
- Simply use the gut feeling of the DT to determine if enough work was selected for the Sprint.

→ Estimating is often helpful, estimates are often not.

Tips:
- Whatever you do in terms of estimation, make sure to do it with the entire DT.
- Create time buckets with increasing intervals (e.g. 1 hour, 2–3 hours, 3–5 hours, 5–8 hours) for teams that like time-based approaches.
- Explore different techniques and determine what works best for the DT, and requires as little effort and time as possible.
- Figure out what problem the customer wants to solve and determine how you'll know when it is solved.
- With software development “I don't know” is a valid answer to questions like “how much will it cost” or “how long will it take”.

### Tips for Agile Product Roadmaps and Product Roadmap Examples

Product roadmap:
- is a high-level, strategic plan, that describes the development of the product over the next period of time.
- support the products' purpose and vision and helps the PO to keep their stakeholders aligned.
- makes it easier to coordinate the development of different products and foster transparency to manage customer expectations.

Too much features can create a lack of focus on the vision and goals.

#### Goal Oriented product roadmap (GO product roadmap)

- Facilitates a lot of focus on the goals than the actual work to be done (the features).
- Enables value steering (steering on outcome) instead of steering on work packages (steering on output).
- Supports in thinking about the most valuable features that enable the achievement of your goals.

![Screenshot 2023-03-01 at 18 16 39](https://user-images.githubusercontent.com/70877098/222125171-276e0de5-752d-4da8-b0eb-668c39b2da6c.png)

#### Now-Next-Later product roadmap

- Is a visualization that easy to understand for everyone.
- Focused more on the features, rather than the goals/objectives you would like to achieve as a Product Owner.
- Doesn't offer much room for including KPI's, releases or dates which offers you the opportunity to interact with your stakeholders, instead of them reading the data from your roadmap.

![Screenshot 2023-03-01 at 18 16 45](https://user-images.githubusercontent.com/70877098/222125181-97541a52-f198-4efe-a04a-3fe7a997849e.png)

#### Story map

- Suitable for using in the beginning of new projects or products. 
- Create a nice overview of all the features you and your stakeholders can think of and all the user activities that need to be covered by the system.
- Provide a nice starting point to facilitate creative ideas for your product.
- Helps you with brainstorming about the product from a users' perspective.
- Creates the illusion that all the features for the product will be developed. 

![Screenshot 2023-03-01 at 18 16 52](https://user-images.githubusercontent.com/70877098/222125191-596fef41-0aba-4c75-b0d6-8bbda7db95dd.png)

#### 11 Summarized Tips

1. Start with your product vision (tip: use [Roman's Product Vision board](http://www.romanpichler.com/tools/vision-board/)).
2. Describe and validate your [product strategy](http://www.romanpichler.com/blog/elements-definition-product-strategy/).
3. Focus on goals and benefits, by creating a [goal oriented product roadmap](http://www.romanpichler.com/blog/goal-oriented-agile-product-roadmap/).
4. Tell a coherent story about the likely growth of your product and don't oversell it.
5. Keep it simple! Resist the temptation to add too much details to your roadmap.
6. Actively collaborate with stakeholders to ensure buy-in.
7. Have the courage to say no, to prevent an overload of features in your roadmap.
8. Think twice about adding timelines, dates or deadlines to your roadmap.
9. Make sure your roadmap is measurable, by adding measurable goals and KPI's.
10. Create a rough estimate for each feature (#people + required skills) to determine the viability of a feature.
11. Review and adapt your product roadmap on a regular basis.

### Release Planning and Predictable Delivery

Software is an organisational asset and decisions to cut quality need to be reflected in your company accounts.
Decisions need to made by your executive leadership and should not be made by Developers.
Quality is non-negotiable, and your Developers focus on creating usable increments of working software.

#### Why is software so unpredictable

With software, everything takes its own amount of time → can really know how long something took after it has been completed.
Once developed, we can know exactly how long it will take to make each one, and then systematically optimize the process that is used to make it.
Expend effort to make the forecast as accurate as possible while accepting that more time spent planning does not necessarily affect the accuracy of that forecast.

![Screenshot 2023-03-06 at 11 50 01](https://user-images.githubusercontent.com/70877098/223058701-b4b4b301-f6be-4cf6-a0a6-9a22d13fd83a.png)

Ultimately Software Development is a creative endeavour and has the same lack of predictability that painting a picture, writing a book or making a movie:
- Have a Director (Product Owner) that has a bunch of money and a delivery plan.
- Have a Producer (Scrum Master) to make sure that everyone has the skills, knowledge and assets available at the right time and place.
- Have one or more Units (Scrum Teams) that have all of the skills necessary to turn the Directors ideas into a working movie. 
- Create Storyboards of what they expect to create and share with the stakeholders and get feedback. 
- Take those storyboards to the Units who collaboratively work together with the stunt, prop, lighting, camera, sound and wardrobe crews to get estimates and costs and ultimately coordinating to create the movie.
- Sometimes. don't know how to do stuff and have to have a go and see what they get.

#### Accept the lack of predictability

There are only three classifications of size: __small__ & __fits__ in a Sprint, or __too big__ for a Sprint.

#### Focus on continuous quality

"If you put developers under pressure to deliver they will continuously and increasingly cut quality to meet deadlines"

A lack of quality of the code results in an increase in a [Technical Debt](https://nkdagility.com/blog/professional-scrum-teams-build-software-works/):
- Have to spend more time struggling with the complexity of the software rather than on new features.
- Will be an increasing number of bugs found in production.

When technical debts are out of control, here are some tips:
1. Create a short measurable checklist that mirrors minimum releasable product (Defenition of Done).
2. Stop adding new features and make the product meet that checklist and release the product.
3. Work to create something of value (Increment).
  - Work towards a new goal while meeting the DOD (Sprint Goal).
  - Leave things better than you found them (Engineering Excellence).
4. Review that thing of value with your stakeholders (Sprint Review, Backlog Adaption).
  - Get feedback on at least one new thing for stakeholders.
  - Update the Backlog to reflect this new information.
5. Reflect on how you worked with your entire team (Sprint Retrospective, Kaizen)
  - Is the quality increasing?
  - Is the DOD increasing?
  - What can we change to make things better?

Some strategies to handle technical debt by stop creating them and then pay a little back each iteration:
- __Sufficient requirements__ → follow the INVEST (Independent, Negotiable, Valued, Estimable, Small, Testable ) model for every single thing that you ask the team to deliver.
- __Developers choose what they can deliver__ → the Backlog Items can be put on the queue for refinement and refined over the next Sprint.
- __Definition of Done (DoD)__ →  Done for Developers should equal what it means to complete an item with no further work required to ship it.
- __Test First__ → Focus on Test First practices like [TDD or ATDD](https://nkdagility.com/blog/you-are-doing-it-wrong-if-you-are-not-using-test-first/).
- __Fixed-length iterations__.
- __No separate teams__ → development teams own the entire application life cycle.
- __Manage dependencies__ → minimize the number of dependencies that you have by adding individuals that you need to the team.
- __Use a modern source control system__ → should include all of the goodies talked about in DevOps practices and beyond.

### Small Batch Delivery and Big Batch Finance: How to Speak the Language of Forecasting

#### The Problem

Writing software can always be written better, more concise, more readable and maintainable, even in the same language with the same tools → can't estimate a problem solved a year ago by using the same way.

On the delivery side, complexity is managed by breaking large projects up into small and manageable pieces that can be delivered quickly → is agile and can respond quickly to change.

#### More on managing complexity

Similar to forecasting hurricane or stock markets.

To understand forecasting complex projects, you need to understand the cone of uncertainty:

![Screenshot 2023-03-06 at 15 20 04](https://user-images.githubusercontent.com/70877098/223055244-fdcb533d-c6f9-48d0-8e1f-bd8e3c20ba86.png)

- When you are close to done, estimates vary less. 
- When you are much further from done, estimates vary much more and it's not a linear relationship.
→ You want to be closer to done when you estimate. The further you are, the worse.

#### Explaining "incremental finance" to senior leaders

- Long-range estimates include exponentially increasing variance as predicted by the cone of uncertainty → break up large initiatives into smaller deliverable and valuable pieces.
- Projects often get batched larger and larger → resist that urge and encourage your senior leaders to do the same.

### Scrum Myths: There is No Planning in Scrum

Consequences of this myth:
- The people in organizations responsible for budgets, product management, sales, and marketing may be unwilling to try Scrum.
- Scrum Teams may not be effective in their use of Scrum.

→ The reality is we plan __A LOT__ in Scrum and just plan differently to optimize effectiveness → "Plans are useless, but planning is indispensable".

- Emphasize the activity of planning over the plan itself → plan is going to change.
- The activity of planning is collaborative.
- The people doing the work own the plan → The Development Team owns the Sprint Backlog. They create it, and they can adapt it.
- Planning in Scrum is part of every Event → The essence of planning is inspecting and adapting.
- The planning ways help reduces waste:
  - Minimize time spent analyzing things that may never happen.
  - Minimize time spent analyzing to an impossible level of accuracy.
  - Incorporate meaningful feedback every time we plan.
- Recognize the inherent unpredictability in complex software development → be transparent about the current progress and likely completion dates → helps build trust.

## Product Vision

### The Professional Product Owner and the Three Vs

The Product Owner role is rarely understood properly:
- Many end up as requirements secretaries (scribes) or requirements traffickers (proxies).
- Wait for their next orders. 

![Screenshot 2023-03-06 at 16 20 08](https://user-images.githubusercontent.com/70877098/223068389-b2c854fc-3a53-4717-b127-2e2161d9113a.png)

→ Come up with the three Vs — Vision, Value, and Validation:
- __Vision__ → Why are we building it? Whose lives will be improved by it?
- __Value__ → Is it customer satisfaction? Operating costs? Registrations? How will we measure it? How do we know when the value received no longer outweighs the costs?
- __Validation__ → shorten the feedback loop by validating frequently with internal experts and the external marketplace.

The three Vs fit perfectly with the three pillars of empiricism:
- __Vision__ creates __Transparency__.
- Defining __Value__ provides you with something to __Inspect__.
- __Validation__ causes __Adaptation__.

### Why, How, and What: From Product Vision to Task

"People don't buy what you do, but why you do it"

Three circles contained in each other that define:
- What you are doing
- How you are doing it
- Why you are doing it

![Screenshot 2023-03-06 at 17 26 09](https://user-images.githubusercontent.com/70877098/223084139-b03b39b2-ed96-4435-8d3c-1d60c88763f0.png)

The Product Vision is important as many teams don't know → the "Golden Product Circle":

![Screenshot 2023-03-06 at 17 26 13](https://user-images.githubusercontent.com/70877098/223084483-5385eb56-bd58-4d3d-afd3-9e677082c18d.png)

- The development starts with __why__, the Product Vision. 
- Then PO can think about __how__ this purpose might be fulfilled, the functions and features of the product in the Product Backlog. 
- The DT then has to build the product and decide on the __what__ to do to deliver the how. They might decompose the Product Backlog into Tasks if it helps them.
- Everything can be referred back to the next higher level → when stuck with the __what__, the DT can look back at the __how__. If a PO has doubts around a __how__, they can look back at the __why__ and try to figure out if this specific __how__ adds to reaching the __why__.

## Product Value

### How Being Yelled at by Users Changes your Perspective on Customer Value

Reasons:
- DT has no feedback from who is gonna use the system.
- Get DT to change their thought process is difficult.
- Don't spend time sharing the reasons/visions with the people.
- Control the work DT did.

Solutions:
- Admit customers were right.
- Look for a change on how we did things to mainly get customer feedback in the loop.
- Create meaningful outcomes for people.
- Get to the why behind the actions to analyze cleary the situation. (e.g., What are you trying to achieve? What did you try but failed? etc.)
- Prepare the ground for the changes to happen, not enforcing it.

### A Scrum Adoption Story - How we delivered value in 7 days

Example: Banking - work on process improvement items such as auditing workflows, help looking for gaps, etc.

Problem:
Different people have different ideas and want own kind of things. There were cost issues on the operations that needs to be optimized.

Solution:
- Gather a team from different fields.
- Discuss together to find a repeatable process to deal with current issues.
- Try out the process and get feedback loop per each iteration.
- Continue with the above process.

### Plan Driven vs. Value Driven Development

Plan Driven model (aka. Waterfall):
- Business Team provide a bunch of requirements.
- DT won't start implementing if the requirements are not finalized.
- Customers won't be able to see the project until all steps are finished (analyze, design, dev, test, release).
- Is rigid (have to go through change requirement process), low visibility, and plan centric.

Value Driven model:
- Order requirements based on highest to lowest value items.
- DT implements the items using iterations (e.g., 1 month).
- Release can be made per iterations and provided to customers for feedback.
- Is flexible (easy to change requirements), high visibility, and customer centric.

## Product Backlog Management

### The Art of Product Backlog Refinement

- Different products and different teams will have unique needs in terms of frequency, techniques, and level of detail. 
- Self-organization and empiricism.

#### The Goldilocks Principle and Product Backlog Refinement

The Goldilocks Principle is about: 
- Find what is “just right” for your team.
- Balance gaining enough benefits from the activity while minimizing the potential waste.

6 benefits of Product Backlog refinement with Goldilocks questions:

1. Increase transparency:
  - How well do stakeholders and the Scrum Team understand what is planned for the product?
  - How frequently are the interested stakeholders surprised by what was delivered?
2. Clarify value → helps the Development Team build the right thing to meet the need:
  - How often do you discover during a Sprint that there is not a shared understanding of the business need or what you are building to meet it?
  - How frequently do you discover in a Sprint Review or after a release that a PBI does not meet the user or business need?
3. Break things into consumable pieces:
  - How often are you not delivering a “Done” Increment?
  - How often are you not meeting a Sprint Goal?
  - When is this attributed to discovering mid-Sprint that PBIs are much bigger than you thought or not sliced thin enough?
4. Reduce dependencies: 
  - How often do you discover dependencies during a Sprint that jeopardize the Sprint Goal?
  - How long do PBIs in a Sprint stay “blocked” by dependencies?
  - When do you have to re-order the Product Backlog to account for dependencies? 
  - How much of an impact does the reorder have on the Product Owner's ability to optimize value?
5. Forecasting → Scrum does not forbid up-front planning:
  - How much lead time is necessary for users, customers, and other stakeholders to implement a new feature or function?
  - What is the impact if they have less lead time?
  - How much detail do users, customers, and other stakeholders need in release forecasts?
  - What is the impact if they have less detail?
6. Incorporate learning:
  - How are you adapting the Product Backlog to reflect new learning about the product's evolving capabilities and how users are responding to the changes?
  - What opportunities have been missed?
  - What prevented you from responding sooner?

### 5 Strategies for Product Backlog Refinement

#### Why is Product Backlog refinement needed?

Product Backlog items are broken down until the DT are fairly confident that they can complete them within a Sprint. The risk is exposed by not completing an item within a Sprint.

Tips: 
- It is time-efficient to refine only the top items in the Product Backlog → will inevitably learn new things that change their view of items further down or make them redundant.
- DT should only spend 10% of their time to refine top items.

#### 5 Strategies for Product Backlog refinement

- __Gaining insights__ → some tools to facilitate this discovery:
  - [Hypothesis Canvas](https://jeffgothelf.com/blog/leanuxcanvas-v2/): "We believe we make progress towards the [product goal] when [users] achieve the [outcome] with [feature]."
  - [UX Fishbowl](https://www.liberatingstructures.com/18-users-experience-fishbowl/): consists of 2 groups and 2 steps, 1 being the stakeholders and 1 the Scrum Team (ST). Stakeholders are invited to discuss questions (e.g., "Imagine this feature was already part of the product. How, when, and why would you use it? What steps are involved? What makes it useful to you? What might deter you?") → The ST listens carefully and notes essential insights. Then, the ST comes together and formulates follow-up questions, which is served for the next round.
- __Ordering the Product Backlog__:
  - [Buy a Feature](https://www.innovationgames.com/buy-a-feature/): 
    1. PBIs that can be bought are priced and listed. 
    2. Money is divided equally among the stakeholders.
    3. Stakeholders buy Product Backlog items that are most important to them. Each item can only be bought once. Stakeholders can combine their money when purchasing.
    4. When all money is spent, the bought items in the list reflect the collectively important items to the stakeholders.
  - [20/20 Vision](https://gamestorming.com/2020-vision/):
    1. Each item of the Product Backlog is a separate card.
    2. Cards are shuffled and a face-down pile is formed.
    3. The top card is used as a reference and is placed upside down next to the pile.
    4. After revealing the next card, stakeholders decide whether it is more or less important to them and place it above or below the reference card accordingly.
    5. The process of grouping the remaining cards into the new list is repeated until the last card in the pile. A 20/20 vision of the order of the Product Backlog is created, which shows what is important to stakeholders. 
- __Estimating Product Backlog items__:
  - [Magic Estimation](https://medium.com/the-liberators/magic-estimation-5165df2be245): 
    1. The numbers 1,2,3,5,8,13,21,? of the Fibonacci series up to 21, supplemented by a question mark, form possible size values.
    2. A PBI is jointly assigned a size and serves as a reference for the assignment of the remaining items. 
    3. The remaining PBIs are distributed among the DTs.
    4. The DTs assign a size to each of their PBIs in relation to the reference entry. If they do not understand an item, the question mark is assigned. The assignment process is done in silence.
    5. After all PBIs have been assigned, the developers inspect the assignments done by others. A new size will be assigned if they disagree with the current size of the item.
    6. If no unique size can be assigned to a PBI, a size between the two values is assigned to it. If a question mark has been assigned to an item, further clarification with the PO's involvement is needed until a unique size can be assigned.
  - [Planning Poker](https://wingman-sw.com/papers/PlanningPoker-v1.1.pdf): 
    1. The PO explains the PBIs to be estimated.
    2. Each DT member individually estimates the item by assigning it a size. All choices remain hidden until everyone has estimated the item. Then, DTs compare their choice. 
    3. If there is no agreement on the size, the DTs engage in a conversation over differences and re-estimated again (step 2). This cycle is repeated until an agreement is reached. This agreement reflects the shared understanding of the PBIs.
- __Breaking down of Product Backlog items__:
  - Break down Product Backlog items by workflow steps (e.g., As a customer, I can log in with my account, pay for my order, receive a confirmation email with my order).
  - Break down Product Backlog items by happy and unhappy paths (e.g., a happy path: `As a customer, I can log in with my account`, a unhappy path: `As a customer, I can reset my password if the login fails`).
  - Further breakdown [strategies](https://drive.google.com/file/d/1bcX_7eJ9iXFygShK0OleZkZy41tY1-0d/view). 
- __Eliminating dependencies__ → there are Internal (PBIs depend on each other) and External (PBIs depend on external factors) dependencies:
  1. Identify the dependencies in the Product Backlog.
  2. Highlight dependencies with arrows to clarify how the items depend on each other or on external factors.
  3. Create a graph using all items as nodes and with the dependencies arrows as edges.

### Myth 14: Refinement is a Required Meeting for the Entire Scrum Team

Refinement is __not__ an event in Scrum → Product Backlog Refinement is something that DTs do as a natural part of development.

#### The purpose of Product Backlog refinement in Scrum

Tip:
- Break down and clarify only those items that we're about to start work on (say next Sprint or one soon after)

![Screenshot 2023-03-06 at 18 51 23](https://user-images.githubusercontent.com/70877098/223102626-a992d353-6ea8-4313-b213-119ff3384ebb.png)

Purposes:
- Clarifying items on the Product Backlog that are too unclear to start work on.
- Breaking down items that are too big to pull into a Sprint.
- Re-ordering the Product Backlog as needed to make the upcoming Sprints as smooth and valuable as possible.
- Adding or removing items from the Product Backlog as new insights emerge.
- Estimating the effort involved in implementing particular items.
- A gut feeling (“Yeah, we know well enough what needs to be done and it feels doable in a Sprint”) is fine.

#### Try the converge-diverge pattern

Issues:
- Not all activities related to refinement are ideally suited to do with the whole team.
- Breaking down items is often a complex activity requiring significant creativity and time to think things through → Meetings are often not the best environment to do.
- There is a natural flow to development during a Sprint → break this flow as infrequently as possible.
- Sitting down around a conference table in a meeting room is not a very engaging way of doing complex work.

_Diverge-Converge Pattern_ is:
- Decide which items need to be clarified or broken down and who wants/needs to be involved.
- The smaller groups then do this work during the Sprint or during ‘Breakouts’ (Diverge) and share their results with the Scrum Team at a later moment during the Sprint to decide on next steps together (Converge).
- Multiple Diverge-Converge cycles can happen during a Sprint depending on the complexity.
→ Make sure that refinement remains a collective effort of the team.

#### More tips to refine work differently

- Invite the Scrum Team to form smaller groups that take responsibility for the refinement of particular items during the upcoming Sprint.
- Don't use tools (like JIRA) during refinement. Instead, refine work with post-its or drawings and ask the team to enter it into the tool afterwards. If you really need to use tools during refinement, make sure that everyone has access to it and can work in it collaboratively.
- Combine Liberating Structures or other facilitation techniques to turn boring refinement sessions into highly interactive sessions where everyone is fully engaged:
  - Invite people to [draw the problem](http://gamestorming.com/draw-the-problem/).
  - Use [1–2–4-ALL](http://www.liberatingstructures.com/1-1-2-4-all/) to quickly identify potential strategies.
  - Use [Troika Consulting](http://www.liberatingstructures.com/8-troika-consulting/) to give and get help
  - Use supporting material, like [our sheet with 10 potential strategies](https://medium.com/the-liberators/10-powerful-strategies-for-breaking-down-user-stories-in-scrum-with-cheatsheet-2cd9aae7d0eb) for breaking down work.
  - Invite stakeholders to participate in refinement where needed.
  - Invite team members to decide for themselves if they want to join meetings where the purpose is to break down specific items → nobody showing up can be a good topic for the upcoming Sprint Retrospective.
  - Experiment with what works for your team.
  - Make use a physical Product Backlog for easily adding information for refinement.
  - Instead of doing refinement during a meeting, go for a walk outside to break down work with your team or subgroup.

### If Your Backlog Is Not Refined Then You Are Doing It Wrong

#### What does ready mean for a Product Backlog?

"Selecting how much can be completed within a Sprint may be challenging. However, the more the DTs know about their past performance, their upcoming capacity, and their Definition of Done, the more confident they will be in their Sprint forecasts."

#### How do you refine your backlog?

As much as you need and no more.

"Product Backlog refinement is the act of breaking down and further defining Product Backlog items into smaller more precise items. This is an ongoing activity to add details, such as a description, order, and size. Attributes often vary with the domain of work."

#### How do you monitor your refinement effectiveness?

DTs should be able to quickly select many PBIs that go towards the chosen Sprint Goal and most of the Items delivered → doing enough refinement.
At the Sprint Review, the PO always wants to reject that Backlog Items are complete → not enough refinement for the DT to understand what they are expected to do.

### An Introductory Video Series to Scrum: Product Backlog & Product Goal

- A Product: Scrum Team + stack holders and users understand the boundaries.
- A project: short-term effort.
- A Product Backlog:
  - Has order, continuously change and evolve when more is learnt about the product.
  - Contains multiple PBIs.
  - Any technique to order the PBIs needs to be transparent and understood.
  - PBIs are more refined as they move towards the top of the backlog.
- No Product Backlog Refinement event.
- PM provides the descriptions for PBIs, while DT defines their sizes.
- Scrum Team decides which sizing technique to use → different teams can provide different sizes for the same item.
- Velocity based on sizing can be used to forecast work can be done in a sprint (no value for stack holders though).
- Product Goal: 
  - A commitment to Product Backlog.
  - 1 product goal at a time.
  - Should be aspirational and measurable.
  - Create focus for Scrum Teams.
  - PBIs are independent, purposeful, and need to meet the product Goal.
- Product without a Product Goal is a headless chicken. 
