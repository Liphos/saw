#!/bin/bash
#SBATCH --job-name=correct_adv
#SBATCH --output=logs/correct_adv_%A_%a.out
#SBATCH --error=logs/correct_adv_%A_%a.err
#SBATCH --array=0-359  # 2 algos * 6 envs * 6 subgoal_steps * 5 seeds
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=10
#SBATCH --gres=gpu:volta:1
#SBATCH --constraint=volta32gb

unset SLURM_CPU_BIND

SEEDS=(3917 3502 8948 9460 4729)
ALGOS=("hiql" "saw")
ENVS=(
    "pointmaze-giant-navigate-v0"
    "pointmaze-large-navigate-v0"
)
SUBGOAL_STEPS=(5 10 25 50 100 250)

NUM_ALGOS=${#ALGOS[@]}
NUM_ENVS=${#ENVS[@]}
NUM_SUBGOAL_STEPS=${#SUBGOAL_STEPS[@]}
ALGO_IDX=$((SLURM_ARRAY_TASK_ID % NUM_ALGOS))
ENV_IDX=$(((SLURM_ARRAY_TASK_ID / NUM_ALGOS) % NUM_ENVS))
SUBGOAL_STEP_IDX=$(((SLURM_ARRAY_TASK_ID / (NUM_ALGOS * NUM_ENVS)) % NUM_SUBGOAL_STEPS))
SEED_IDX=$((SLURM_ARRAY_TASK_ID / (NUM_ALGOS * NUM_ENVS * NUM_SUBGOAL_STEPS)))

SEED=${SEEDS[$SEED_IDX]}
ALGO=${ALGOS[$ALGO_IDX]}
ENV=${ENVS[$ENV_IDX]}
SUBGOAL_STEP=${SUBGOAL_STEPS[$SUBGOAL_STEP_IDX]}

source .venv/bin/activate

EXTRA_ARGS=("--agent.subgoal_steps=${SUBGOAL_STEP}")

case "$ENV" in
    cube-single-play-v0)
        if [ "$ALGO" = "saw" ]; then
            EXTRA_ARGS+=(--agent.kl_alpha=0.3)
        fi
        ;;
    cube-double-play-v0)
        if [ "$ALGO" = "saw" ]; then
            EXTRA_ARGS+=(--agent.kl_alpha=1.0)
        fi
        ;;
    humanoidmaze-large-navigate-v0 | humanoidmaze-giant-navigate-v0)
        EXTRA_ARGS+=(--agent.discount=0.995)
        ;;
esac

srun python main.py \
    --env_name="$ENV" \
    --eval_episodes=50 \
    --agent="agents/${ALGO}.py" \
    --seed="$SEED" \
    --run_group="${ALGO}_correct_adv" \
    "${EXTRA_ARGS[@]}"
