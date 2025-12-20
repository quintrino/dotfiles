// locknow.c

// Warning: Code was pulled from
// https://stackoverflow.com/questions/1976520/lock-screen-by-api-in-macos/26492632#26492632
// Was posted 21 Oct 2014 so may cease functioning at any time!!!

// Definitely options for improvement; see above link for other ideas and links to posts
// that might have better long-term support (e.g. written in Swift with a supported API?)

// Build it using this command:
// $ clang -F /System/Library/PrivateFrameworks -framework login -o locknow locknow.c

extern int SACLockScreenImmediate ( void );

int main ( ) {
    return SACLockScreenImmediate();
}
