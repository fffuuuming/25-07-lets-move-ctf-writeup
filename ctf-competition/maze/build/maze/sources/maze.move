module maze::maze {
    use sui::event;
    use std::string::{Self, String};

    const E_NOT_OWNER: u64 = 1;
    const E_CHALLENGE_NOT_COMPLETE: u64 = 2;
    const E_CHALLENGE_ALREADY_COMPLETE: u64 = 3;


    const ROW: u64 = 10;
    const COL: u64 = 11;

    const MAZE: vector<u8> = b"#S########\n#**#######\n##*#######\n##***#####\n####*#####\n##***###E#\n##*#####*#\n##*#####*#\n##*******#\n##########";

    const START_POS: u64 = 1;


    public struct ChallengeStatus has key, store {
        id: UID,
        owner: address,
        challenge_complete: bool,
    }

    public struct FlagEvent has copy, drop {
        sender: address,
        flag: String,
        github_id: String,
        success: bool,
    }
    
    public struct InvalidMove has copy, drop {}
    
    public struct HitWall has copy, drop {}
    
    public struct Success has copy, drop {
        path: String,
    }

    public entry fun create_challenge(ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);

        let challenge = ChallengeStatus {
            id: object::new(ctx),
            owner: sender,
            challenge_complete: false,
        };

        transfer::public_transfer(challenge, sender);
    }

    
    public entry fun complete_challenge(
        challenge: &mut ChallengeStatus,
        moves: vector<u8>,
        ctx: &mut TxContext,
    ) {
        let sender = tx_context::sender(ctx);
        assert!(challenge.owner == sender, E_NOT_OWNER);
        assert!(!challenge.challenge_complete, E_CHALLENGE_ALREADY_COMPLETE);
        
        
        let mut current_pos = START_POS;

        let len = vector::length(&moves);
        let mut i = 0;

        while (i < len) {
            let c = *vector::borrow(&moves, i);
            let mut new_pos = current_pos;

            // ASCII values: w=119, s=115, a=97, d=100
            if (c == 119) { 
                if (current_pos >= COL) {
                    new_pos = current_pos - COL; 
                } else {
                    event::emit(InvalidMove {});
                    break
                }
            }
            else if (c == 115) { 
                new_pos = current_pos + COL;
            }
            else if (c == 97) { 
                if (current_pos % COL != 0) {
                    new_pos = current_pos - 1; 
                } else {
                    event::emit(InvalidMove {});
                    break
                }
            }
            else if (c == 100) { 
                if (current_pos % COL != COL - 1) {
                    new_pos = current_pos + 1; 
                } else {
                    event::emit(InvalidMove {});
                    break
                }
            }
            else { 
                i = i + 1; 
                continue
            };

            // Boundary check
            if (new_pos >= ROW * COL) {
                event::emit(InvalidMove {});
                break
            };

            let cell = maze_at(new_pos);

            if (cell == 35) {
                event::emit(HitWall {});
                break
            };

            if (cell == 69) {
                challenge.challenge_complete = true;
                event::emit(Success { path: string::utf8(moves) });
                break
            };

            current_pos = new_pos;
            i = i + 1;
        };
    
    }

    
    public entry fun claim_flag(
        challenge: &ChallengeStatus,
        github_id: String,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(challenge.owner == sender, E_NOT_OWNER);
        
        assert!(challenge.challenge_complete, E_CHALLENGE_NOT_COMPLETE);
        
        event::emit(FlagEvent {
            sender: tx_context::sender(ctx),
            flag: string::utf8(b"CTF{Letsmovectf}"),
            github_id,
            success: true
        }); 
    }

    public fun get_challenge_status(challenge: &ChallengeStatus): (bool) {
        challenge.challenge_complete
    }

    fun maze_at(pos: u64): u8 {
        let maze_ref = &MAZE;
        let row = pos / COL;
        let col = pos % COL;
        let maze_pos = row * COL + col;
        
        assert!(maze_pos < vector::length(maze_ref), 1);
        *vector::borrow(maze_ref, maze_pos)
    }

}