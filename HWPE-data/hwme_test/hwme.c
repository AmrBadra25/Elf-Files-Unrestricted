
#include "pulp.h"
#include <stdint.h>
#include "archi/hwme/hwme_v1_archi.h"
#include "hal/hwme/hwme_v1_hal.h"

#define USE_STIMULI
// comment below line to run only dot product with bias
//#define DO_MATVEC_MULT
#ifndef DO_MATVEC_MULT
    #define DO_DOT_PROD
#endif

#include "OverSampledOFDMSymbols_i.h"
#include "OverSampledOFDMSymbols_r.h"
#include "DPD_out_i.h"
#include "DPD_out_r.h"

int main() {

  uint32_t *in_r       = (uint8_t *) 0x1c010000;
  uint32_t *in_i       = (uint8_t *) 0x1c012000;
  uint32_t *out_r      = (uint8_t *) 0x1c014000;
  uint32_t *out_i      = (uint8_t *) 0x1c016000; //check if this is even available in the memory for the HWPE to use
  uint32_t *expected_r = (uint8_t *) 0x1c018000;
  uint32_t *expected_i = (uint8_t *) 0x1c020000;


  int coreID = get_core_id();

  volatile int errors = 0;
  int gold_sum = 0, check_sum = 0;
  int i,j;
  
  int offload_id_tmp, offload_id;

  if(get_core_id() == 0) {

#ifdef USE_STIMULI
    for(int i=0; i<24960; i++) {
      ((uint8_t *) in_r)[i] = OverSampledOFDMSymbols_r[i];
    }
    for(int i=0; i<24960; i++) {
      ((uint8_t *) in_i)[i] = OverSampledOFDMSymbols_i[i];
    }    
    for(int i=0; i<24960; i++) {
      ((uint8_t *) expected_r)[i] = DPD_out_r[i];
    }
    for(int i=0; i<24960; i++) {
      ((uint8_t *) expected_i)[i] = DPD_out_i[i];
    }
#endif

    /* convolution-accumulation - HW */
    plp_hwme_enable();

    while((offload_id_tmp = hwme_acquire_job()) < 0);

    // set up bytecode
    hwme_bytecode_set(HWME_LOOPS1_OFFS,           0x00000000); //check what do
    hwme_bytecode_set(HWME_BYTECODE5_LOOPS0_OFFS, 0x00040000);
    hwme_bytecode_set(HWME_BYTECODE4_OFFS,        0x00000000);
    hwme_bytecode_set(HWME_BYTECODE3_OFFS,        0x00000000);
    hwme_bytecode_set(HWME_BYTECODE2_OFFS,        0x00000000);
    hwme_bytecode_set(HWME_BYTECODE1_OFFS,        0x000008cd);
    hwme_bytecode_set(HWME_BYTECODE0_OFFS,        0x11a13c05);
    
    // job-dependent registers
    hwme_in_r_addr_set((unsigned int) in_r);
    hwme_in_i_addr_set((unsigned int) in_i);
    hwme_out_r_addr_set((unsigned int) out_r);
    hwme_out_i_addr_set((unsigned int) out_i);

    // coefficients set
    hwme_a10_r_data_set((unsigned int) 0b00000000000000000000111111111100);
    hwme_a30_r_data_set((unsigned int) 0b00000000000000000000000000011011);
    hwme_a50_r_data_set((unsigned int) 0b00000000000000000000000010001011);
    hwme_a10_i_data_set((unsigned int) 0b00000000000000000000000000110001);
    hwme_a30_i_data_set((unsigned int) 0b00000000000000000000000000001000);
    hwme_a50_i_data_set((unsigned int) 0b00000000000000000000000100100001);

    hwme_nb_iter_set(1);  //check what do
    hwme_len_iter_set(6240);
    hwme_vectstride_set(32*4);
    hwme_vectstride2_set(32*4); // same stride for both streams

    // start HWME operation
    hwme_trigger_job();

    // wait for end of compuation
    soc_eu_fcEventMask_setEvent(ARCHI_SOC_EVENT_FCHWPE0);
    //__rt_periph_wait_event(ARCHI_SOC_EVENT_FCHWPE0, 1);

    plp_hwme_disable();

    // check
    //data will probably be overwritten on the results we wrote down anyway, but regardless we should compare
    for(int i = 0; i<6240; i++){
      if(out_r[i] != expected_r[i]) error++;
      if(out_i[i] != expected_i[i]) error++;
    }
    printf("errors=%d\n", errors);

   }
   //synch_barrier();

   return errors;
}
