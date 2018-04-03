# ![Crappy Cards logo](https://cdn.rawgit.com/larsgw/CrappyCards/master/icon.svg) Crappy Cards

A [Happening](https://happening.im) plugin based on [Cards Against Humanity](https://cardsagainsthumanity.com/) (see [LICENSE](https://github.com/larsgw/CrappyCards/blob/master/LICENSE.md)).

> I don't agree with all the content in Cards Against Humanity. Because of that, I'm currently working on labeling the cards, to give the user the option to filter out certain topics. This option will be on by default.

## Install

There is currently no production developer console instance for Crappy Cards. For now, you can deploy it yourself by following these steps (adapted from the [Happening example code](https://github.com/Happening/Example)).

> On Linux/Mac, use your Bash-compatible shell. On Windows, we recommend the Git shell that comes with [Git](http://git-scm.com/download/win).

> 1. Clone the code: `git clone https://github.com/larsgw/CrappyCards.git`.
> 2. Create a **Developer console app** via https://happening.im/store/106 and clicking "Start!".
> 3. Deploy your app using `cd CrappyCards/; ./deploy {deployKey}`. It should instantly update in your browser / app.
> 4. Optionally, copy the __deploy key__ to a file (`echo 1234abcdef > .deploykey`) and use `./deploy` without arguments.

## Contribute

### Bugs & other issues

Report at [GitHub Issues](https://github.com/larsgw/issues).

### Test

Currently, there are no other tests than creating a test environment and running it yourself. On how to deploy the app, see the *Install* guide above.

### Update cards

1. Clone the code: `git clone https://github.com/larsgw/CrappyCards.git`.
2. Install dev packages: `npm install`
3. Change the version in `updateCards.js` (at `cardsUrl`). Try to make sure that the card and pack IDs match up.
4. Run script: `node updateCards.js`

### Classify cards

Help with classifying cards would be very welcome, but is currently not viable.
