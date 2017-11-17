#!/bin/sh

# Monitors survey results for TEDx 2017, subverting the drawbacks of having
# a free Poll Everywhere account

# directory for results
RESULTS="results"

# user authentication (I know this is unsafe)
AUTH="YWRhbWNvb3BlcjM2ODpTUlNseVdIMEY0cnQzRA=="

# poll permalink
URL="PollEv.com/adamcooper368"

# poll title
TITLE="Test!"

# seconds in an hour
HOUR=$((60 * 60))

# max votes to get before reset
VOTE_CEILING=480

# poll URL extension
permalink=""

# poll ID
id=0

# poll start time in seconds
starttime=0

# number of polls run so far
numpolls=1

# tells monitoring to die
kill=0

# tells if currently monitoring
monitoring=0



# extracts a variable from a json object
extractvar() {
    echo "${2}" | grep -Po "(?<=\"${1}\":)[^,]*" | head -1 | sed -e 's/\"//g'
}



# creates a new simple text poll
newpoll() {
    polldata=$(curl -X POST -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Basic $AUTH" -d "{\"multiple_choice_poll\":{\"id\":null,\"updated_at\":null,\"title\":\"$TITLE\",\"opened_at\":null,\"permalink\":null,\"state\":\"closed\",\"sms_enabled\":true,\"twitter_enabled\":null,\"web_enabled\":true,\"sharing_enabled\":null,\"simple_keywords\":null,\"options\":[{\"id\":0,\"value\":\"Bird\",\"keyword\":null},{\"id\":1,\"value\":\"Book\",\"keyword\":null},{\"id\":2,\"value\":\"Guitar\",\"keyword\":null},{\"id\":3,\"value\":\"Yoga\",\"keyword\":null},{\"id\":4,\"value\":\"Hand\",\"keyword\":null},{\"id\":5,\"value\":\"Comedy/Tragedy\",\"keyword\":null},{\"id\":6,\"value\":\"Telescope\",\"keyword\":null},{\"id\":7,\"value\":\"Gear\",\"keyword\":null},{\"id\":8,\"value\":\"Flower\",\"keyword\":null},{\"id\":9,\"value\":\"Boat\",\"keyword\":null},{\"id\":10,\"value\":\"Dog\",\"keyword\":null},{\"id\":11,\"value\":\"Thundercloud\",\"keyword\":null},{\"id\":12,\"value\":\"Tree\",\"keyword\":null},{\"id\":13,\"value\":\"Airplane\",\"keyword\":null},{\"id\":14,\"value\":\"Building\",\"keyword\":null},{\"id\":15,\"value\":\"Heart\",\"keyword\":null}]}}" "https://www.polleverywhere.com/multiple_choice_polls")

    permalink=$(extractvar "permalink" "$polldata")
    id=$(extractvar "id" "$polldata")

    #echo $permalink
    #echo $id
    #echo $polldata
}



# starts the created poll
startpoll() {
    #echo "https://www.polleverywhere.com/multiple_choice_polls/$permalink"

    curl -X PUT -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Basic $AUTH" -d "{\"multiple_choice_poll\":{\"id\":$id,\"updated_at\":null,\"title\":\"$TITLE\",\"opened_at\":null,\"permalink\":\"$permalink\",\"state\":\"opened\",\"sms_enabled\":true,\"twitter_enabled\":null,\"web_enabled\":true,\"sharing_enabled\":null,\"simple_keywords\":null,\"options\":[{\"id\":0,\"value\":\"Bird\",\"keyword\":null},{\"id\":1,\"value\":\"Book\",\"keyword\":null},{\"id\":2,\"value\":\"Guitar\",\"keyword\":null},{\"id\":3,\"value\":\"Yoga\",\"keyword\":null},{\"id\":4,\"value\":\"Hand\",\"keyword\":null},{\"id\":5,\"value\":\"Comedy/Tragedy\",\"keyword\":null},{\"id\":6,\"value\":\"Telescope\",\"keyword\":null},{\"id\":7,\"value\":\"Gear\",\"keyword\":null},{\"id\":8,\"value\":\"Flower\",\"keyword\":null},{\"id\":9,\"value\":\"Boat\",\"keyword\":null},{\"id\":10,\"value\":\"Dog\",\"keyword\":null},{\"id\":11,\"value\":\"Thundercloud\",\"keyword\":null},{\"id\":12,\"value\":\"Tree\",\"keyword\":null},{\"id\":13,\"value\":\"Airplane\",\"keyword\":null},{\"id\":14,\"value\":\"Building\",\"keyword\":null},{\"id\":15,\"value\":\"Heart\",\"keyword\":null}]}}" "https://www.polleverywhere.com/multiple_choice_polls/$permalink"

    starttime=$(date +%s)
}



# stops the created poll
stoppoll() {
    curl -X PUT -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Basic $AUTH" -d "{\"multiple_choice_poll\":{\"id\":$id,\"updated_at\":null,\"title\":\"$TITLE\",\"opened_at\":null,\"permalink\":\"$permalink\",\"state\":\"closed\",\"sms_enabled\":true,\"twitter_enabled\":null,\"web_enabled\":true,\"sharing_enabled\":null,\"simple_keywords\":null,\"options\":[{\"id\":0,\"value\":\"Bird\",\"keyword\":null},{\"id\":1,\"value\":\"Book\",\"keyword\":null},{\"id\":2,\"value\":\"Guitar\",\"keyword\":null},{\"id\":3,\"value\":\"Yoga\",\"keyword\":null},{\"id\":4,\"value\":\"Hand\",\"keyword\":null},{\"id\":5,\"value\":\"Comedy/Tragedy\",\"keyword\":null},{\"id\":6,\"value\":\"Telescope\",\"keyword\":null},{\"id\":7,\"value\":\"Gear\",\"keyword\":null},{\"id\":8,\"value\":\"Flower\",\"keyword\":null},{\"id\":9,\"value\":\"Boat\",\"keyword\":null},{\"id\":10,\"value\":\"Dog\",\"keyword\":null},{\"id\":11,\"value\":\"Thundercloud\",\"keyword\":null},{\"id\":12,\"value\":\"Tree\",\"keyword\":null},{\"id\":13,\"value\":\"Airplane\",\"keyword\":null},{\"id\":14,\"value\":\"Building\",\"keyword\":null},{\"id\":15,\"value\":\"Heart\",\"keyword\":null}]}}" "https://www.polleverywhere.com/multiple_choice_polls/$permalink"
    getresults
    numpolls=$(($numpolls+1))
}



# gets the results of the created poll and redirects them to a JSON file
getresults() {
    curl -s -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Basic $AUTH" "https://www.polleverywhere.com/multiple_choice_polls/$permalink/results" > "results/poll$numpolls.json"
}



# monitors polls for response numbers and hourly times
monitorpoll() {
    monitoring=1
    prevvotes=0
    # forever
    while [ 0 -lt 1 ]; do
        getresults
        #printf "$(cat "$RESULTS/poll$numpolls.json")"
        votes=$(cat "$RESULTS/poll$numpolls.json" | sed -e 's/voter_id/\n/g' | wc -l)
        now=$(date +%s)

        # notify us of new votes coming in
        if [ "$votes" -ne "$prevvotes" ]; then
            printf "Votes: %3d %s\n" $votes $(date +%T)
        fi

        # if we've obtained >= ceiling votes or it's been an hour since we started our last poll
        if [ $votes -ge $VOTE_CEILING ] || [ $(($now-$starttime)) -ge $HOUR ]; then
            stoppoll
            printf "Poll stopped, results recoreded\n"
            printf "New poll beginning...\n"
            newpoll
        fi

        # check for "kill" signal
        if [ $kill -ne 0 ]; then
            monitoring=0
            stoppoll
            kill=1
            break
        fi
    done
}


#################################################
###################  BODY  ######################
#################################################


# if there isn't a results directory yet
if ! [ -d $RESULTS ]; then
    mkdir $RESULTS
fi



# if we haven't created a poll yet
if [ -z "$permalink" ]; then
    newpoll
fi



# forever
while [ 0 -lt 1 ]; do
    read command

    case $command in
        "start") if [ $monitoring = 0 ]; then
                     startpoll
                     monitorpoll &
                 fi
        ;;
        "stop") if [ $monitoring = 1 ]; then
                    kill=1
                fi
        ;;
        "new") if [ $monitoring = 1 ]; then
                   starttime=0
               fi
        ;;
        "quit") kill=1
                wait $!
                exit 0
        ;;
    esac
done
