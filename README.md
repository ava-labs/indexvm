<p align="center">
  <img width="90%" alt="indexvm" src="assets/logo.png">
</p>
<p align="center">
  The Context Layer of the Decentralized Web
</p>
<p align="center">
  <a href="https://github.com/ava-labs/indexvm/actions/workflows/unit-tests.yml"><img src="https://github.com/ava-labs/indexvm/actions/workflows/unit-tests.yml/badge.svg" /></a>
  <a href="https://github.com/ava-labs/indexvm/actions/workflows/sync-tests.yml"><img src="https://github.com/ava-labs/indexvm/actions/workflows/sync-tests.yml/badge.svg" /></a>
  <a href="https://github.com/ava-labs/indexvm/actions/workflows/static-analysis.yml"><img src="https://github.com/ava-labs/indexvm/actions/workflows/static-analysis.yml/badge.svg" /></a>
</p>

The `indexvm` is dedicated to increasing the usefulness of the world's
content-addressable data (like IPFS) by enabling anyone to "index it" by
providing useful annotations (i.e. ratings, abuse reports, etc.) on it.
Think up/down vote on any static file on the decentralized web.

The transparent data feed generated by interactions on the `indexvm` can
then be used by any third-party (or yourself) to build an AI/recommender
system to curate things people might find interesting, based on their
previous interactions/annotations.

Less technical plz? Think TikTok/StumbleUpon over arbitrary IPFS data (like NFTs) but
all your previous likes (across all services you've ever used) can be used to
generate the next content recommendation for you.

The fastest way to expedite the transition to a decentralized web is to make it
more fun and more useful than the existing web. The `indexvm` hopes to play
a small part in this movement by making it easier for anyone to generate
world-class recommendations for anyone on the internet, even if you've never
interacted with them before.

## Status
`indexvm` is considered **ALPHA** software and is not safe to use in
production. The framework is under active development and may change
significantly over the coming months as its modules are optimized and
audited.

We created the `indexvm` while building the [`hypersdk`](https://github.com/ava-labs/hypersdk)
to test out our design decisions and abstractions. It is the first `hypervm` built using this new framework.

## Terminology
* `Searcher`: looks for interesting content on the decentralized web and
  records it on-chain (earning a reward when their content is referenced)
* `Servicer`: recommends data to `Users` by analyzing historical on-chain data
* `Users`: rates content discovered by `Searchers` and recommended by
  `Servicers`

It is important to note that any of these participants may be a single entity
(a servicer may also search for content, for example) but they don't need to
be. It is possible for some AI wizard (a `Servicer`) to provide stellar
recommendations to `Users` but have no idea how to actually find the
interesting and useful content they are recommending.

## Features
### Generic On-Chain Metadata Storage
You can use `Index` [actions](https://github.com/ava-labs/hypersdk#action) to persist
arbitrary content (up to 1.6KB for now) in state for other participants to ingest and reference.
Each uploaded content is given a canonical identifier (the hash of `parent`+`content`) and
the `indexvm` will reject the indexing of identical content by other participants. The goal
of the `indexvm` is to make decentralized data more useful, not to be the storage layer for
all decentralized data, so the `indexvm` bounds arbitrary data storage to a size that should
be sufficient for storing references/annotations of data on other storage mediums but nothing
more than that.

_In the future, it is possible that the `indexvm` could offer best-effort storage of large
files over the `hypersdk's` network layer but that is currently reserved for "Future Work"._

#### User-Defined Data Schema
When persisting some content to state using an `Index` action, the submitter
must provide a `Schema` to describe the content. This schema is user-defined
and can be any 32-byte value but is generally advised to be the hash of some
[human-readable value](https://github.com/ava-labs/indexvm/blob/main/examples/shared/consts/consts.go).
Requiring all index events to specify a schema makes it much easier for data
indexers and recommenders to filter by content they care about and to employ
custom parsers that can actually read arbitrary data (or skip it if it doesn't
adhere to an expected format).

There are examples schemas for [NFTs](https://github.com/ava-labs/indexvm/blob/main/examples/nftdisco/thegraph/thegraph.go#L73-L107),
[memes](https://github.com/ava-labs/indexvm/blob/main/examples/memedisco/reddit/models/meme.go), and
[user ratings](https://github.com/ava-labs/indexvm/blob/main/examples/shared/gorse/gorse.go#L20-L72) in the
`examples` directory.

#### Native Data Linking
Each `Index` action can optionally specify a parent that is is associated with.
This allows anonymous participants to build on the activity or discoveries of others
in a structured manner that allows anyone ingesting the activity feed to
recognize without parsing an action's `Content`.

While this may sound like a niche feature, linking to content is a very common
activity on the `indexvm`. The typical interaction pattern for most `Users` is to provide a
"rating" of some parent that they were recommended.

### Enforceable Rewards
Searching for interesting content on the decentralized web and uploading it to
a deployment of the `indexvm` requires an investment of time, talent, and resources.
To reward searchers for interesting discoveries, the `indexvm` enables
`Searchers` to enforce that any content that references content they uploaded must
pay some uploader-specified fee.

#### Note on Avoiding Fees: "Voting for Copy Cats"
`Users`, acting in their own best interest (getting the best recommendations),
should not seek "copy cat" content from cheaper, alternative sources because
submitting ratings for nearly identical objects (which have different IDs than the
original content) will result in strictly worse future recommendations.

Most recommender systems today utilize some derivative of collaborative filtering,
which provides content recommendations based on the shared overlap of preferences
you have with other users instead of using any information about the object you vote on.
Voting for copies with minute changes (which would have different IDs) is the equivalent of voting
for "new" content to these algorithms, not similar data going by a different moniker.
This type of voting effectively reduces the overlap you could form with other like-minded
users and makes it more difficult for the collaborative filtering algorithm analyzing
your past activity to recommend enjoyable content.

Not to mention, the best content discoverers would not be incentivized
to continue uploading their discoveries if they weren't paid fairly for doing
so.

### State Bloat Fee
The `indexvm` requires the sender of any transaction (often called the `Actor`)
to lock `StateLockup` funds for each item that they add to state. These funds
are then unlocked when the state previously added is removed. This experimental
mechanism seeks to properly charge participants for the additional strain their
allocation of additional state puts on the rest of the network (slower block
exectuion, slower state sync, more disk usage, etc.).

_In the future, it is likely that not all `StateLockup` funds will be refunded
to an `Actor` when an object is removed from state. Although there are already fees for
removing state objects, they may not be enough to discourage a malicious
participant from rapidly adding/removing objects to increase block verification
time (i.e. target modification of the underlying chain state may be underpriced)._

### ...Everything in the `hypersdk`
The `indexvm`, a `hypervm` focused on indexing decentralized data, inherits the features
and performance characteristics of the underlying `hypersdk` framework it builds on.
This means that the `indexvm` gets state sync, optimized block execution, nonce-less transactions,
and support for generic storage backends, etc. out-of-the-box.

You can learn more about the `hypersdk` [here](https://github.com/ava-labs/hypersdk).

## Actions
To learn more about `Actions`, check out this
[link](https://github.com/ava-labs/hypersdk#action).

### Authorize
```golang
type Authorize struct {
	// Actor must be specified so we can enumerate read keys
	Actor crypto.PublicKey `json:"actor"`
	// Signer is the new permissions
	//
	// Any balance pull must come from actor to avoid being able to steal other's
	// money.
	Signer crypto.PublicKey `json:"signer"`

	ActionPermissions uint8 `json:"actionPermissions"`
	MiscPermissions   uint8 `json:"miscPermissions"`
}
```

The `Authorize` action enables any account owner to grant another account owner
granular permissions over their account. This is useful when creating
server-based searchers that only have the ability to add new content but not
transfer funds. Additionally, this action can be used to rotate the admin key
of an account (give all priviliges to new key, revoke all priviliges from
current key).

### Clear
```golang
type Clear struct {
	// To is the recipient of [Actor]'s funds
	To crypto.PublicKey `json:"to"`
}
```

The `Clear` Action transfers all funds in an account to another account and
deletes it from state. This state deletion also refunds the `LockupState` to
[To].

### Index
```golang
type Index struct {
	// REQUIRED
	//
	// Schema of the content being indexed
	Schema ids.ID `json:"schema"`
	// Content is the indexed data that will be associated with the ID
	Content []byte `json:"content"`

	// OPTIONAL
	//
	// Royalty is the amount required to reference this object as a parent in
	// another [Index]
	//
	// If this value is > 0, the content will be registered to receive rewards
	// and the creator will need to lock up [Genesis.ContentStake]. To deregister an item
	// from receiving rewards and to receive their [Genesis.ContentStake] back, the creator must
	// issue an [UnindexTx].
	//
	// If this value is 0, the content will not be registered to receive rewards.
	Royalty uint64 `json:"royalty"`

	// Parent of the content being indexed (this may be nested)
	//
	// This can also be empty if there is no parent (first reference)
	Parent ids.ID `json:"parent"`

	// Searcher is the owner of [Parent]
	//
	// We require this in the transaction so that the owner can be prefetched
	// during execution.
	Searcher crypto.PublicKey `json:"searcher"`

	// Servicer is the recipient of the [Invoice] payment
	//
	// This is not enforced anywhere on-chain and is up to the transaction signer
	// to populate correctly. If not populate correctly, it is likely that the
	// service provider will simply stop serving the user.
	Servicer crypto.PublicKey `json:"servicer"`

	// Commission is the value to send to [Servicer] for their work in surfacing
	// the content for interaction
	//
	// This field is not standardized and enforced by a [Servicer] to provide
	// user-level flexibility. For example, a [Servicer] may choose to offer
	// a discount after performing so many interactions per month.
	Commission uint64 `json:"commission"`
}
```

The `Index` action is the main interaction on the `indexvm`. It is used both
for recording new content (by `Searchers`) and for rating existing content (by
`Users`). Because it is common for `Users` to get recommendations from
`Servicers`, it is also possible to pay a commission to `Servicers` when
logging a rating (instead of needing to send an additional transfer).
`Servicers` typically require some commission per X recommendations to cover
the cost of running their recommender systems.

It is optional to enforce a `Royalty` (fee that must be paid when referencing
`Content`) because `Users` have no need to do so for their individual ratings
(which would not likely be referenced in the regular course of actions). This
also means that each of their ratings don't lock `LockupState` of their balance
(like it does for `Searchers` that upload discovered content).

### Modify
```golang
type Modify struct {
	// Content is the content to update
	Content ids.ID `json:"content"`

	// Royalty is the new value to apply to the content
	Royalty uint64 `json:"royalty"`
}
```

The `Modify` action is used to modify the `Royalty` that must be paid when
referencing `Content` in an `Index` action. `Searchers` may lower the price of
old content that is no longer frequently referenced in a bid to capture more
revenue (`Servicers` may prefer to serve "affordable" content to `Users`).

### Transfer
```golang
type Transfer struct {
	// To is the recipient of the [Value].
	To crypto.PublicKey `json:"to"`

	// Amount are transferred to [To].
	Value uint64 `json:"value"`
}
```

The `Transfer` action is the simplest interaction on the `indexvm`. It is used
to transfer funds to any other account. If the recipient doesn't exist, the account is created,
`LockupState` funds are locked, and the default permissions are assigned to the
`crypto.PublicKey` recipient.

### Unindex
```golang
type Unindex struct {
	// Content is the content to unindex
	//
	// This transaction will refund [Genesis.ContentStake] to the creator of the
	// content.
	Content ids.ID `json:"content"`
}
```

The `Unindex` action simply removes a previously uploaded piece of `Content`
from state. This is useful when `Content` is no longer referenced by others and
a `Searcher` feels uploading a new piece of content could be more profitable
(so they use the `LockupFunds` locked here elsewhere).

## Auth
To learn more about `Auth`, check out this
[link](https://github.com/ava-labs/hypersdk#auth).

### Direct
```golang
type Direct struct {
	Signer    crypto.PublicKey `json:"signer"`
	Signature crypto.Signature `json:"signature"`
}
```

`Direct` authentication is just a `Signature` for a given `Signer`. The
`Signer` will be the `Actor` in any `Action` they authenticate.

### Delegate
```golang
type Delegate struct {
	Actor     crypto.PublicKey `json:"actor"`
	Signer    crypto.PublicKey `json:"signer"`
	Signature crypto.Signature `json:"signature"`

	ActorPays bool `json:"actorPays"`
}
```

`Delegate` authentication lets the `Signer` serve as the `Actor` of some
`Action`, if the `Actor` previously authorized them to do so. This makes it
possible, for example, for a `Signer` to index data on the behalf of another
`Actor` and for that `Actor` to then revoke the `Signer` without losing the
reputation they built up. This is particularly useful for `Actors` that use
external servers to upload new content (and don't want to give those servers
the ability to transfer funds).

## Running the `indexvm`
### Load Test
The `indexvm` load test will provision 5 `indexvms` and process 500k transfers
on each between 10k different accounts.

```bash
./scripts/tests.load.sh
```

### Integration Test
The `indexvm` integration test will run through a series of complex on-chain
interactions and ensure the outcome of those interactions is expected.

```bash
./scripts/tests.integration.sh
```

### E2E Test
The `indexvm` E2E test spins up 5 AvalancheGo nodes and performs a simple
transfer.

```bash
MODE=test ./scripts/run.sh
```

If you want to a full suite of sync tests (state syncs new nodes
while thousands of blocks are being processed concurrently), run the following
command:

```bash
MODE=full-test ./scripts/run.sh
```

### Local Network
The `indexvm` spins up 5 AvalancheGo nodes and logs how they can be accessed.
This is commonly used for local experimentation.

```bash
./scripts/run.sh
```

## Examples
To showcase the capability of the `indexvm`, we implemented some useful
[example applications](https://github.com/ava-labs/indexvm/tree/main/examples).

These examples include but are not limited to:
* Avalanche NFT Searcher
* Meme (Reddit) Searcher
* Generic Recommendation Server
* CLI-Based Content Viewer + Voter

You can check out this package for instructions on how to run a full `indexvm`
demo.

## Zipkin Tracing
To trace the performance of `indexvm` during load testing, we use `OpenTelemetry + Zipkin`.

To get started, startup the `Zipkin` backend and `ElasticSearch` database (inside `hypersdk/trace`):
```bash
docker-compose -f trace/zipkin.yml up
```
Once `Zipkin` is running, you can visit it at `http://localhost:9411`.

Next, startup the load tester (it will automatically send traces to `Zipkin`):
```bash
TRACE=true ./scripts/tests.load.sh
```

When you are done, you can tear everything down by running the following
command:
```bash
docker-compose -f trace/zipkin.yml down
```

## Future Work
_If you want to take the lead on any of these items, please
[start a discussion](https://github.com/ava-labs/indexvm/discussions) or reach
out on the Avalanche Discord._

* Cleanup E2E tests (lots of duplicated code that should be simplified)
* Make `LockupFunds` proportional to the size of state being stored
* Increase `MaxContentSize` (blocked on `x/merkledb`)
* Make the `LockupFunds` refund less than `LockupFunds`
* Provide a best-effort storage mechanism for large files using a DHT running
  on top of the `hypersdk` networking layer
* Add support for sending assets between different `indexvms` (blocked on
  `hypersdk` support for Avalanche Warp Messaging)
