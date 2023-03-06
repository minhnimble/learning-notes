# Developing and Delivering Products Professionally

## Emergent Software Development

### Getting to Done: Balancing Emergence and Delivery

3 Challenges Balancing Emergence and Delivery:

#### 1 - New work is being assigned to the Development Team

Nobody should be adding work to the Sprint Backlog except the DT.

Ideas for handling emerging priorities not in line with the Sprint Goal:
- A Scrum Master protects the Scrum Team from outside distractions by teaching them the rules of Scrum → helping them understand their accountability and what decisions they own. 
- Team members hold each other accountable → having support from entire team to question and say "not now" is helpful.
- DT and the PO should negotiate → Sprint Goal should not be changed during the Sprint.

#### 2 - Poor Product Backlog refinement causes the "what" to grow during the Sprint

- Consider having the full Scrum Team participate in Product Backlog refinement.
- May choose to make this more formal with a [Definition of Ready](http://www.romanpichler.com/blog/the-definition-of-ready/) - clear, feasible, and testable.
- A Scrum Master coaches the PO on how to best fulfill their role and responsibilities to the team with some [great questions](https://blog.scrum.org/10-product-owner-questions/).

#### 3 - Not discussing the "how" during Sprint Planning.

- A Scrum Master should reinforce the purpose of Sprint Planning.
- A Scrum Master can help the team more effectively use the time-box → use open questions to draw out this part of the discussion.
  - "This is a large item. How can we break this down into smaller pieces the team can tackle together?"
  - "Do we have everything we need as a team to meet our Definition of Done and achieve the Sprint Goal?"
  - "What dependencies will drive how we deliver on the Sprint Goal?"
- Break the Product Backlog Items into tasks or to-dos → offer the team the option to take what they have visually captured and break down the PBIs into tasks on the Scrum Board.

### Dispelling the Myth that Scrum Teams Don't Think About Architecture

Scrum Team Work without Documentation → both True and False:
- True: Scrum Framework doesn't require document.
- False: Software typically require documentation.

→ Lightweight documentation: Enough details, correctness, regularly updated (e.g., Spotify click to play feature).

Whiteboard architecture:
- Red: What is being worked on.
- Green: What target looks like.

Plastic Pocket: 
- Until work is started:
  - 1 pocket per PBI.
  - easily pulled in refinement session.
  - handmake sketches, drawings, etc.

 - DoD example:
  - Put photo in Dropbox.
  - Paste photo in Google Docs.
  - Document finalized solution in EA.

Software Quality Goals:

![Screenshot 2023-03-06 at 22 47 30](https://user-images.githubusercontent.com/70877098/223160537-9e9a1b27-00ae-450b-b6bd-92af090a4ec3.png)

→ Pick the most 3 - 5 important goals for the organization.

Basic architecture:

![Screenshot 2023-03-06 at 23 40 00](https://user-images.githubusercontent.com/70877098/223174352-7086424e-abab-423d-a8cf-59eb861ffd62.png)

Architecture "Prezel":

![Screenshot 2023-03-06 at 23 41 59](https://user-images.githubusercontent.com/70877098/223174752-e2332683-a8d9-4997-9160-b00f8be7f432.png)

→ In software development, architecture ideas are not valid until proven out in a working system.

For example, we have 2 teams work on the same product but choose different architecture approach for implementing data source layer - NHibernate (ORM objective-relational mapping tool) vs Entity Framework (dotnet project):

![Screenshot 2023-03-06 at 23 46 38](https://user-images.githubusercontent.com/70877098/223175867-00d83bb1-a489-468f-8469-7dba52dded96.png)

→ Ask the following questions:
- What's the cost change?
- Is there a more important dimension? (Use of Repository pattern, etc.)
- If we want consistency, how do we get there? (Setting expectations, consensus building patterns, communities of practice)

Unforeseen rebuild key points:
- Keep adding value to the product.
- Keep the product shippable.
- Communicate effectively.

Make large changes incrementally by:
- Branch by abstraction.
- Treat vendor product as black boxes to build upon.
- Use existing tests as expected functionality.
- Build along side existing functionalities.
- Migrate clients as their need are met.

In large Nexus teams, when there are different opinions:
- What is the cost to build both solutions? (maybe a POC for each solution and compare the pros and cons).
- Be a servant leader, and build consensus, no need to dictate.
- Find the best architecture solution from the community practices.

How to keep the rework cost low if we can't define the architecture upfront?
- Build a little things to get little piece of value first.
- Come up with concepts first is okay.
- Make use of backlog refinements.
- open conversations across teams to get a forward look.
- Weight the cost of not changing.

Why can't we have spring zero?
- We can never be done with it as there is no way to get the stuffs right from the beginning.

### The Importance of Vertically Slicing Architecture

Image how a baby develop:
- All the subsystem are created and start to grow. 
- Vertically slide the architecture by doing a little of database, API, UI, etc. and perfect them overtime → Still can deploy a viable product if anything goes wrong (unlike a headless baby). 

## Managing Technical Risk

### Slaying Technical Debt

Why have Technical Debt?
- Application quickly expands outside the bounds we initially planned.
- Made bad decisions in the past.

Consequence of Technical Debt:
- Release were more buggy.
- Slower to code.
- More difficult to code around these areas of technical debts.

Actions:
- Do product backlog refinement during a sprint.
- Brainstorm the PBIs around technical debts on a board or management tool.
- Bring them to spring planning sessions and make sure DTs own the technical debts.

### Technical Debt vs. Not "Done" Work

Technical Debt:
- DTs do work at the level of quality they don't like (e.g., hard-code config files instead of proper configs from server).
- Sometimes are unknown in costs and can cost more if we just do it right in the first place.

Not "Done" Work:
- Work can't be completed within a Sprint (e.g., use 3rd-party tools will need legal license reviews (unknown length to complete) before going to production).
- Potential invalidate the old work, not just future sprints → too much risks and should not be let lingering around.

### Managing Risk

Innovation are high risks (Tesla, Boombox, etc.)

Risk has also a lot to do with our own personal involvement e.g., if someone I don't know will cross two buildings on just a rope without safety net, that's very risky for that person, but not for me.

Types of risks:
- Financial risk - can we pay for it?
  - PO is in control of the budget and planning of the product.
  - self-managing DT of cross-functional professionals who can get the job done, from start to finish.
  - Scrum Master facilitates Scrum Team to encourage empirical process control and coaches the team to be a little bit better every day.
  - Ask Developers how long it will take them to build a concrete result. The shorter the better, because that saves money, that might otherwise be wasted on building the wrong thing.
  → Fund just a couple of Sprints at first and look at the results after every Sprint + have a conversation with the Scrum Team about the results and the return on investment → The costs are pretty predictable (the costs of the team + out of pocket expenses for these Sprints) → The sooner the first release goes out to the users, the sooner the financial risk decreases!
- Business risk - will it be used? Does it solve the problem?
  - Startups build things nobody wanted → setup 1 cross-functional problem team that answers who is the customers, and what problems we are trying to solve + 1 solution team (engineering team) try to answer the above questions.
  - PO is a business representative in the team to manage and monitor that business risk, to create the best possible outcome.
- Technical risk - Can it be build with a good ROI? Can we maintain the product during and afterwards?.
  - Communication between DTs and PO if the effort that is put into a certain feature is worth the value is key here.
  - Whenever you encounter bad technical quality, make it (at least a little bit) better.
  - Technical skills, tools and improvements can be adopted in a good definition of done. The right testing, validation, documentation etc. can reduce the technical risk.

→ The best way to reduce risk in general is: build potentially releasable increments for customers.

## Optimizing Flow

### Kanban Guide for Scrum Teams

Kanban Guide for Scrum Teams - 2021 (PDF English version): ![Kanban_Guide_01-2021](/resources/Kanban_Guide_01-2021.pdf)

#### Definition 

Kanban: a strategy for optimizing the flow of value through a process that uses a visual, work-
in-progress limited pull system.

#### Kanban with Scrum Theory - Flow and Empiricism

Flow is the movement of value throughout the product development system.

Key to empirical process control is the frequency of the transparency, inspection, and adaptation cycle - which we can also describe as the Cycle Time through the feedback loop.

#### Kanban with Scrum Theory - The Basic Metrics of Flow

The 4 basic metrics of flow that Scrum Teams using Kanban need to track:
- Work in Progress (WIP): The number of work items started but not finished. Provide transparency about their progress towards reducing their WIP and improving their flow.
- Cycle Time: The amount of elapsed time between when a work item starts and when a work item finishes.
- Work Item Age: The amount of time between when a work item started and the current time. Apply only to items that are still in progress.
- Throughput: The number of work items finished per unit of time.

#### Little’s Law – The Key to Governing Flow

![Screenshot 2023-03-07 at 00 53 59](https://user-images.githubusercontent.com/70877098/223191401-98a25767-ac05-41d2-9d4b-aa87950d7e4c.png)

#### Kanban Practices

Achieve flow optimization by using the following four practices:
- Visualization of the Workflow - the Kanban Board:
  - Defined points at which the Scrum Team considers work to have started and to have finished.
  - A definition of the work items. (most likely Product Backlog items (PBIs))
  - A definition of the workflow states that the work items flow through from start to finish. (at least one active state)
  - Explicit policies about how work flows through each state.
  - Policies for limiting Work in Progress (WIP).
- Limiting Work in Progress (WIP):
  - Is a pull system that the team starts work on an item only when it is clear that it has the capacity to do so. (not push system, which demands that work starts on an item whenever it is requested)
  - Improves the Scrum Team's self-management, focus, commitment, and collaboration.
- Active management of work items in progress:
  - Making sure that work items are only pulled into the Workflow at about the same rate
that they leave the Workflow.
  - Ensuring work items aren't left to age unnecessarily.
  - Responding quickly to blocked or queued work items as well those that are exceeding the team's expected Cycle Time levels (Service Level Expectation - SLE):
    - SLE forecasts how long it should take a given item to flow from start to finish.
    - SLE has 2 parts: a range of elapsed days and a probability associated with that period (e.g., 85% of work items should be finished in eight days or less). 
- Inspecting and adapting the team's Definition of Workflow:
  - Visualization policies e.g., Workflow states - either changing the actual Workflow or bringing more transparency to an area.
  - How-we-work policies - these can directly address an impediment e.g., adjusting WIP limits and SLEs or changing the batch size can have a dramatic impact.

#### Flow-Based Events

- The Sprint.
- Sprint Planning.
- Daily Scrum. Additional things to consider:
  - What work items are blocked and what can be done to get them unblocked?
  - What work is flowing slower than expected? What is the Work Item Age of each item in progress? 
  - What work items have violated or are about to violate their SLE and what can the Scrum Team do to get that work completed?
  - Are there any factors not represented on the board that may impact our ability to complete work today?
  - Have we learned anything new that might change what the Scrum Team has planned to work on next?
  - Have we broken our WIP limit? And what can we do to ensure we can complete the work in progress?
- Sprint Review.
- Sprint Retrospective.
  - Using a cumulative flow diagram to visualize a Scrum Team's WIP, approximate average Cycle Time and average Throughput can be valuable.

#### Increment

Kanban helps manage the flow of these feedback loops more explicitly and allows the Scrum Team to identify bottlenecks, constraints, and impediments.

### Understanding the Kanban Guide for Scrum Teams

#### Core Kanban practices

- Visualization of the workflow
- Limiting WIP
- Active management of work items in progress
- Inspecting and adapting their definition of "Workflow"

#### Advanced Kanban concepts 

- Classes of Service
- Cost of Delay
- Flow Efficiency

→ They are not part of the guide because we don't consider them part of the “Minimally viable set of practices” a Scrum team should focus.

#### Application of the Kanban Method

- Limiting your work in process and moving to a disciplined pull mode is far from being easy, but it's still evolutionary compared to changing team structures, roles, process flows.
- A professional Scrum team should actually have an easier time limiting WIP than most.

#### ScrumBan

ScrumBan as a way to introduce Lean/Kanban flow into a Scrum context – while keeping the core Scrum process intact. 

#### Why/When add Kanban to Scrum

- Think about how hard it is for them to Sprint and whether they feel like they have good flow during the Sprint. 
- When Scrum teams struggle to achieve good sustainable healthy flow.

#### When Kanban with Scrum is bad

- When Scrum Teams don't understand Kanban or use it as an escape from the challenges of Scrum.
- When the team isn't looking to improve.

### Agile For Humans Podcast 108: Professional Scrum with Kanban with Yuval Yeret

#### How flow metrics can help your teams improve

- Allow the team to be aware of the flow transparency. (e.g., Cycle time - start to finish)
- Detect when team is blocked with WIP metric.
- Optimize the sprint with throughput.
- Burn the burn-down chart.
- Create a Kanban board to track work items.

#### Why Scrum and Kanban fit well together

- Kanban improves empiricism from Scrum.
- Kanban makes Scrum practices better - a modern way of Scrum.
- DevOps (CI/CD) flows create feedback loops for the work items and deployments.

#### When to use Lean and Kanban practices on your Scrum Team

- Looking for ways to scale support.

### Limiting Work in Progress (WIP) in Scrum with Kanban - What / When / Who / How

![Screenshot 2023-03-07 at 01 20 14](https://user-images.githubusercontent.com/70877098/223197210-753e69b2-3304-4260-ab39-7a82ec3a871a.png)

#### Who should define the WIP Limit? 

Scrum Team that would own the workflow and therefore would need to discuss WIP limits.

#### Should WIP limits be changed to deal with mid-sprint high-priority work? 

- First, a decision needs to be made whether to pull this item into the Sprint Backlog.
- Then, the DTs need to figure out whether they can actually start it right away, which depends on the WIP limits and the current WIP.
- NOT to change the WIP limit definition but to go above WIP and note a WIP exception.

#### When should the WIP limits be inspected and adapted? 

- Don't changing WIP limits on a whim.
- Scrum Teams should adjust WIP limits during the Sprint Retrospective out of an attempt to create a better flow strategy.
- In the end, there is nothing stopping them from adjusting WIP limits at ANY point throughout the Sprint.

#### How should Scrum teams limit their WIP? 

Can limit the amount of work in progress per:
- person.
- the entire team throughout their workflow.
- by time e.g., "we won't work on more than 10 items this week"

### Steve Porter on Scrum with Kanban

#### Scrum with Kanban

- Improve how to do software.
- What is really alarming is Kanban is forced to used on Scrum, which can lead to negative things for teams.
- Self-organized Scrum Teams must make the decisions themselves to use Kanban to visualize their work or not.
- Have 4 best practices.

#### Scrumban

- No need additional `Scrumban` masters, existing roles of Scrum should be suffice.
