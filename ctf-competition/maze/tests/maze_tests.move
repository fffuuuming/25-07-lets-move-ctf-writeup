#[test_only]
module maze::maze_tests {
    use sui::test_scenario::{Self as ts};
    use maze::maze::{ChallengeStatus};
    use maze::maze::{create_challenge, complete_challenge, get_challenge_status};
    use std::debug::{print};

    #[test]
    fun test_maze() {
        let sender = @0xcafe;
        let mut s = ts::begin(sender);

        // 1. Create a challenge
        s.next_tx(sender);
        create_challenge(s.ctx());

        // // 2. Retrieve the challenge object created and transferred to sender
        s.next_tx(sender);
        let mut challenge = s.take_from_sender<ChallengeStatus>();
        print<ChallengeStatus>(&challenge);

        // 3. Build the correct path to reach the goal 'E'
        // move: [sdssddssaasssddddddwww]
        // ASCII values: w=119, s=115, a=97, d=100
        let moves: vector<u8> = vector[
            115,
            100,
            115,
            115,
            100,
            100,
            115,
            115,
            97,
            97,
            115,
            115,
            115,
            100,
            100,
            100,
            100,
            100,
            100,
            119,
            119,
            119
        ];

        // 4. Try completing the challenge
        complete_challenge(&mut challenge, moves, s.ctx());

        // 5. Ensure challenge is marked complete
        let complete = get_challenge_status(&challenge);
        print(&complete);
        s.return_to_sender(challenge);
        s.end();
    }
}