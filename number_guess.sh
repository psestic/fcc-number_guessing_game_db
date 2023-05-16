#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

MAIN() {
  # Ask for user input
  echo "Enter your username:"
  read USERNAME

  # Check whether user is a regular or new and greet accordingly
  DATABASE_REQUEST

  # Set up the game
  GUESS_COUNT=0
  NUMBER=$((1 + $RANDOM % 1000))

  # Let the user play the game
  GUESS "Guess the secret number between 1 and 1000:"
}


DATABASE_REQUEST(){
  # get user id from database
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME';")

  # if not in database
  if [[ -z $USER_ID ]]
  then
    # insert user in database
    ADD_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES ('$USERNAME')")
    if [[ $ADD_USER_RESULT == "INSERT 0 1" ]]
    then
      # welcome the new user
      echo -e "Welcome, $USERNAME! It looks like this is your first time here."
    fi
    # get new user id
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME';")

  # if already in database
  else
    # get number of games and best game
    USER_INFO=$($PSQL "SELECT MIN(guesses) AS best_game, COUNT(user_id) AS games_played FROM games WHERE user_id=$USER_ID;")
    echo $USER_INFO | while IFS="|" read BEST_GAME GAMES_PLAYED
    do
      echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
    done
  fi
}

GUESS() {
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi
  
  # get a guess as input
  read GUESSED_NUMBER

  # check if input is valid
  if [[ ! $GUESSED_NUMBER =~ ^[0-9]+$ ]]
  then
    GUESS "That is not an integer, guess again:"

  else
    # increase number of guesses
    GUESS_COUNT=$((GUESS_COUNT+1))
    
    # if correct guess
    if [ $GUESSED_NUMBER -eq $NUMBER ]
    then
      # enter game result in database
      ENTRY_RESULT=$($PSQL "INSERT INTO games(user_id,guesses) VALUES ($USER_ID, $GUESS_COUNT)")
      # congratulate the user 
      echo -e "\nYou guessed it in $GUESS_COUNT tries. The secret number was $NUMBER. Nice job!"

    # if guess is too high  
    elif [ $GUESSED_NUMBER -gt $NUMBER ]
    then 
      GUESS "It's lower than that, guess again:"

    # if guess is too low
    elif [ $GUESSED_NUMBER -lt $NUMBER ]
    then 
      GUESS "It's higher than that, guess again:"
    fi
  fi
}


MAIN


